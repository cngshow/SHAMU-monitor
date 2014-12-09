require './jobs/ruby/helpers/job_jvm_prop_loader.rb'
require './jobs/tasks/message_replay/test_pids.rb'

module ReplayMessages
  include ReplayHelpers
  include JobJVMPropLoader

  VHA       = "VHACHDR.MED.VA.GOV"
  DOD       = "DODCHDR.HA.OSD.GOV"
  VA_TO_DOD = "VA_TO_DOD" #VA Z03-> DOD
  DOD_TO_VA = "DOD_TO_VA" #DOD Z03-> VA
  ICN_ACTIVE = true
  ICN_INACTIVE = false
  @caip_initialized = false

  def process_additional_args
    @direction = $additional_arguments.shift
    @only_903 = $additional_arguments.shift.to_i.eql?(1)
    return unless @only_903
    @terminology_xml = $additional_arguments.shift
    @caip_component_xml = $additional_arguments.shift
    @spring_xml << @caip_component_xml
    @spring_xml << @terminology_xml
    jvm_props = $additional_arguments.shift
    load_jvm_properties(jvm_props)
  end

  def get_sql
    #you MUST double escape apostrophes in the exclusions as seen below
    #THIS ARE VA Z04 faults (DOD_TO_VA)
    vha_fault_detail_exclusions = <<-vfde
        Lab data is not supported in this release.
        Critical coded value for RXE-2.1 is empty or absent.
        Enterer''s location is empty or absent.
        HDRII_CONSTRAINT_VIOLATED
    vfde
    #FATAL ERROR: errorCode=ROOT_CAUSE_MSG: displayMessage=Persistence Failure Message: {1}.: Could not execute JDBC batch update:

    vha_fault_detail_exclusions = vha_fault_detail_exclusions.split("\n").map{|e| e.strip }.reject{|e| e.start_with?("#")}

    #THESE ARE DOD Z04 faults (VA_TO_DOD)
    dod_fault_detail_exclusions = <<-dfde
        Couldn''t map to an NPI Type 2 ID.  This is required for sending to PDTS.
        Unable to map VA Facility ID
        This is a duplicate message:
        PatientIdInfo not found
        Patient not found for DEERS ID
        The HL7 message did not contain an Order Date for the medication
        ADC status not ACTIVE for patient with DEERS ID
        Medication mapping translation from RXNORM CUI to NDC was not found
        Tuxedo returned an error, DSS service error
        The translation from the UMLS CUI code to an Allergy IEN code returned null or blank
        Error handling update request: null
        PDTSHeaderFactory.toNCPDP51String: NPI Type 2 number couldn''t be found
        Medication mapping translation from RXNORM CUI to NDC was not found
        Dataservice failed to convert SNOMED CT to Reaction Ncid
    dfde

    dod_fault_detail_exclusions = dod_fault_detail_exclusions.split("\n").map{|e| e.strip }.reject{|e| e.start_with?("#")}

    sql = <<-eos
            select a.message_id as message_id,
              trim(a.event_type) as event_type,
              b.fault_code as fault_code,
              b.fault_detail as fault_detail,
              a.message_content as message_content
            from chdr2.audited_event a, chdr2.audited_event b
            where a.sending_site = 'Z03_SENDING_SITE'
            and   a.receiving_site = 'Z03_RECEIVING_SITE'
            and   a.event_type in ('PRES','FILL','ALGY')
            and   a.created_date BETWEEN TO_DATE ('START_DATE','yyyymmdd') AND TO_DATE ('END_DATE','yyyymmdd')
            and   A.MESSAGE_ID = B.CORRELATION_ID
            and   B.FAULT_CODE is not null
            FAULT_DETAIL_EXCLUSIONS
            ONLY_903
            --and rownum < 2001
            order by a.created_date desc
    eos

    if (!@direction.eql?(VA_TO_DOD) && !@direction.eql?(DOD_TO_VA))
      raise "Invalid direction argument supplied as #{@direction}. Valid ARGV are #{DOD_TO_VA} or #{VA_TO_DOD}. Fix commands.txt"
    end

    sending_site   = @direction.eql?(VA_TO_DOD) ? VHA : DOD
    receiving_site = @direction.eql?(VA_TO_DOD) ? DOD : VHA
    fault_detail_exclusions = @direction.eql?(VA_TO_DOD) ? dod_fault_detail_exclusions : vha_fault_detail_exclusions

    #end_date = Time.now + 86400

    #set up the SQL to retrieve replay messages
    sql.gsub!("START_DATE") { |match| @start_date.strftime("%Y%m%d") }
    sql.gsub!("END_DATE") { |match| @end_date.strftime("%Y%m%d") }
    sql.gsub!("Z03_RECEIVING_SITE") { |match| receiving_site }
    sql.gsub!("Z03_SENDING_SITE") { |match| sending_site }

    fault_detail_exclusions.map! { |e|
      " and b.fault_detail not like '%#{e}%' "
    }
    sql.gsub!("FAULT_DETAIL_EXCLUSIONS") { |match| fault_detail_exclusions.join("\n") }

    #if we are only processing 903 errors and this is a DOD_TO_VA (these are all terminology errors as per Keith and will schedule differently)
    #then only include 903 fault codes otherwise exclude 903 errors for DOD_TO_VA
    sql.gsub!("ONLY_903") { |match| @only_903 && @direction.eql?(DOD_TO_VA) ? " and b.fault_code = '903' " : (@direction.eql?(DOD_TO_VA)) ? " and b.fault_code != '903' " : ""}
  end

  def assign_message_id(message_content, message_id)
    message = message_content

    if (message_content =~ /<MSH\.10>(.+?)<\/MSH\.10>/)
      msh10 = $1
      $logger.error("Invalid audit log record. The message id column does not match the MSH.10 segment.") unless message_id.eql?(msh10)
			replay_msg_id = get_replay_message_id(msh10)
			$logger.debug("************New message id is #{replay_msg_id}")

      message = message_content.sub(/<MSH\.10>.+?<\/MSH\.10>/){|m| "<MSH.10>" + replay_msg_id + "</MSH.10>"}

			$logger.debug("************Appending #{message_id} to the XML")
			message << "<!-- Original message id= #{message_id} -->"
    else
      $logger.error("Invalid message content. There was no MSH.10 segment containing the message_id #{message_id}.")
    end

    message
  end

  def call_replay?(fault_code, fault_detail)
    ret = false
    $logger.debug("call_replay? in replay_clinical_updates")

    if (@direction.eql?(DOD_TO_VA))
      if (fault_code.eql?("900"))
        #system failure (Transaction terminated abnormally on VA CHDR server)
        ret = true
      elsif (fault_code.eql?("903"))
        $logger.debug("Call replay for 903 called!")
        #terminology failure with z03 from dod so replay message in hopes that it will pass terminology now
        ret = passes_terminology?(fault_code, fault_detail)
      elsif (fault_code.eql?("904"))
        #error handling individual message in a retrieval request: Hibernate operation: Could not execute JDBC batch update; ....
        ret = true
      elsif (fault_code.eql?("906"))
        #All 906s are these errors and are being excluded above (HDRII_CONSTRAINT_VIOLATED) - do not replay the message as it appears this is a duplicate
        #we are returning true in case there are other 906 errors beside this so they will be captured in the report
        ret = true
      elsif (fault_code.eql?("907"))
        process_907(fault_detail)
      end
    else #VA_TO_DOD
      ret = true
    end
    ret
  end

  def replay_message_call(message_id, event_type, message_content)
    z03_dom = transform_to_dom(message_id, message_content)
    return false if z03_dom.nil?

    begin
      $logger.debug("calling service bus ... z03 dom is" + z03_dom.class.to_s)
      @service_bus.processOutbound("dodComponent", z03_dom) if @direction.eql?(DOD_TO_VA)
      @service_bus.processInbound("dodComponent", z03_dom) if @direction.eql?(VA_TO_DOD)
    rescue => ex
      @service_bus_error_count += 1
      raise ex
    end
    return true
  end

  def process_907(fault_detail)
    ret = false

    #Could not find an active patient cross reference with DOD id:blah VA id:blah
    #pull the VA ICN from the fault detail
    icn = nil

    if (fault_detail =~ /.*VA id:(.*)/)
      icn = $1
      @tracking_hash[:icns][icn] = [0, ICN_INACTIVE] if @tracking_hash[:icns][icn].nil?
      @tracking_hash[:icns][icn][0] += 1
    else
      @tracking_hash[:icn_907_errors][fault_detail] = 0 if @tracking_hash[:icn_907_errors][fault_detail].nil?
      @tracking_hash[:icn_907_errors][fault_detail] += 1
      return
    end

    # return if we have already checked this ICN
    if (@tracking_hash[:icns][icn][0] = 1)
      begin
        #check to see if the VA ICN exists
        statement = $connection.createStatement
        sql       = <<-eos
                select case count(*) when 0 then 'false' else 'true' end as icn_found
                from chdr2.patient_identity_xref a
                where a.vpid = 'VA_ICN' and a.status = 1
        eos

        sql.gsub!("VA_ICN") { |match| icn }
        results = statement.executeQuery(sql)
        results.next

        if (results.getString("icn_found").eql?("true") || $scrub)
          @tracking_hash[:icns][icn][1] = ICN_ACTIVE
        end
      rescue => ex
        $logger.error(ex.backtrace.join("\n"))
        raise ex
      ensure
        results.close() unless results.nil?
        statement.close() unless statement.nil?
      end
    end

    if (@tracking_hash[:icns][icn][1])
      ret = true
    end
		ret = true if $scrub
    ret
  end

  def get_report_result
    #this method returns the html of the tracking results
    start = @start_date.strftime("%Y%m%d")
    finish = @end_date.strftime("%Y%m%d")

    #pull out the counts for the fault codes
    error900, error903, error906, error907, errorICN = [0,0,0,0,0]
    error900 = @tracking_hash[:fault_code_counts]["900"].to_s unless @tracking_hash[:fault_code_counts]["900"].nil?
    error903 = @tracking_hash[:fault_code_counts]["903"].to_s unless @tracking_hash[:fault_code_counts]["903"].nil?
    error906 = @tracking_hash[:fault_code_counts]["906"].to_s unless @tracking_hash[:fault_code_counts]["906"].nil?
    error907 = @tracking_hash[:fault_code_counts]["907"].to_s unless @tracking_hash[:fault_code_counts]["907"].nil?
    errorICN = @tracking_hash[:icns].keys.size.to_s unless @tracking_hash[:icns].size == 0

    ret =  <<-eos
    <div style="width: 980px; border-style: solid; border-width:thin; font-size: 12px; padding-left: 10px">
    <h4>
      Replay Clinical Updates for Z03 Messages From #{@direction.eql?(DOD_TO_VA) ? "DOD" : "VA"} <br>
      Activity for #{start} to #{finish} (Reported in Central Time)<br>
    </h4>
    <div class="section">Replay Results Breakdown</div>
    <div class="rpt_display">
      <table class="display" cellspacing=0>
        <tr>
          <th width="20%">900 Error<br>Count</th>
          <th width="20%">903 Error<br>Count</th>
          <th width="20%">906 Error<br>Count</th>
          <th width="20%">907 Error<br>Count</th>
          <th width="20%">Distinct ICNs<br>From 907</th>
        </tr>
        <tr>
          <td>#{error900}</td>
          <td>#{error903}</td>
          <td>#{error906}</td>
          <td>#{error907}</td>
          <td>#{errorICN}</td>
        </tr>
      </table>
    </div></div>
    eos

    #append the replay results along with the remaining tracked results
    ret << replay_results
    ret << track_fault_results
    ret << track_terminology_failure_results unless @terminology_cache.nil?
    ret << format_tracking_results_for_all_errors(:icn_907_errors, "ICN Lookup Errors")
    ret << format_tracking_results_for_all_errors(:service_bus_errors, "Service Bus Errors")
    ret << format_transform_errors
    ret << service_bus_termination_message
    ret << max_replay_termination_message
  end
  
  def get_scrubbed_pid
		pids = nil

		if ($service_bus_env.eql?("DEV"))
			pids = @direction.eql?(VA_TO_DOD) ? VA_TO_DOD_PIDS_DEV : DOD_TO_VA_PIDS_DEV
		elsif ($service_bus_env.eql?("SQA"))
			pids = @direction.eql?(VA_TO_DOD) ? VA_TO_DOD_PIDS_SQA : DOD_TO_VA_PIDS_SQA
		else
			#	bad environment passed - pids is nil
		end

		unless pids.nil?
			pid_array = pids.gsub("\n","").split(/<\/PID>\s*/).map{|e| e.strip + "</PID>"}
			pid = pid_array[rand(pid_array.size)]
			$logger.debug("************ returning pid: " + pid)
		end
		pid
  end

  def job_specific_init
    initialize_caip if @only_903
  end

  def initialize_caip
    return if @caip_initialized
    @mapping_lookup = @context.getBean("mappingLookup")
    $logger.info("@mapping_lookup is " + @mapping_lookup.to_s)
    @caip_initialized = true
  end

  def passes_terminology?(fault_code, fault_detail)
    raise "This method is only valid on a fault code of 903!" unless fault_code.eql?("903")
    if (fault_detail =~ /.*VETSNotFoundException.*lookupCode=(\w+)/)
      @terminology_code = $1
      @terminology_cache = {} if @terminology_cache.nil?
      unless @terminology_cache[@terminology_code].nil?
        maps = @terminology_cache[@terminology_code][0]
        count = @terminology_cache[@terminology_code][1]
        count += 1
        @terminology_cache[@terminology_code] = [maps,count]
        return maps
      end
      begin
        @terminology_cache[@terminology_code] = [@mapping_lookup.isMapped(@terminology_code),1]
        $logger.debug("The result for terminology_code #{@terminology_code} is " + @terminology_cache[@terminology_code][0].to_s)
      rescue => ex
        $logger.error("Unable to get terminology results for #{@terminology_code}.  Setting the result to false for this code for this run.")
        @terminology_cache[@terminology_code] = [false,1]
      end
    else
      $logger.warn("The following fault detail (fault_code = #{fault_code}) was unexpected!")
      $logger.warn(fault_detail)
      return false
    end
    @terminology_cache[@terminology_code][0]
  end

  def track_terminology_failure_results
    top_results   = @terminology_cache.to_a.reject { |elem| elem[1][0] }.sort { |a, b| b[1][1] <=> a[1][1] }[0..@top_fault_count-1]
    html_template = <<-htm
          <br><br>
          <div style="width: 980px; border-style: solid; border-width:thin; font-size: 12px; padding-left: 10px; padding-right: 10px">
            <h2>Top #{@top_fault_count} Terminology failures by terminology code</h2>
            <table class="display"><tr><th>Terminology Code</th><th>Count</th></tr>
            TOP_RESULTS
            </table>
          </div>
          <br><br>
    htm
    cnt = 0
    details = ""
    top_results.each do |e|
      cnt               += 1
      terminology_code  = e[0]
      terminology_count = e[1][1]
      odd_even          = (cnt % 2) == 1 ? "odd" : "even"
      details           += "<tr class=\"#{odd_even}\"><td>#{terminology_code}</td><td>#{terminology_count}</td></tr>"
    end
    html_template.gsub("TOP_RESULTS", details)
  end

end
