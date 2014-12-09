require 'java'

module ReplayHelpers
  $REPLAY_SUCCESS = 1
  $REPLAY_FAILURE = 2
  $REPLAYED_PREVIOUSLY = 3
  $REPLAY_LABEL = "_r_"
	$RADIX = 36

  java_import 'java.lang.Thread' do |pkg, cls|
   'JThread'
  end

	java_import 'java.lang.System' do |pkg, cls|
   'JSystem'
  end

  def scrubPII(message_content)
    #scrub out PII for testing purposes
    message_content.gsub!(/<PID>.*?<\/PID>/) { |match| get_scrubbed_pid }
    message_content
  end

  def replay_message(message_id, event_type, message_content)
    ret = $REPLAY_SUCCESS

    begin
      if @replay_count < @replay_group_count
        @replay_count += 1
      else
        sleep @replay_pause
        @replay_count = 1
      end

      #$logger.debug("************** @replay_check_hash is " + @replay_check_hash.inspect)
      return $REPLAYED_PREVIOUSLY if @replay_check_hash.has_key?(message_id)
      replayed = replay_message_call(message_id, event_type, message_content)
      @replay_check_hash[message_id] = Time.now if replayed
      ret = $REPLAY_FAILURE unless replayed
    rescue => ex
      $logger.info("replay failed! " + ex.to_s)
      $logger.info(ex.backtrace.join("\n"))
      @tracking_hash[:service_bus_errors][ex.to_s] = 0 if @tracking_hash[:service_bus_errors][ex.to_s].nil?
      @tracking_hash[:service_bus_errors][ex.to_s] += 1
      ret = $REPLAY_FAILURE
    end

    # return ret
    ret
  end

  def processing_complete
    File.open(@replay_check_file, 'w') do |f|
      f.write Marshal.dump(@replay_check_hash)
    end
  end

  #initialize class variables and set up classpath
  def init
    @service_bus_error_count = 0
    @current_time = Time.now
    @tracking_hash = Hash.new
    @tracking_hash[:icn_907_errors] = Hash.new
    @tracking_hash[:replay] = Hash.new #storing the message_id as the key with an array with the event_type and message_content
    @tracking_hash[:fault_code_counts] = Hash.new
    @tracking_hash[:icns] = Hash.new
    @tracking_hash[:transform_errors] = []
    @tracking_hash[:service_bus_errors] = Hash.new
    @my_class_loader = JThread.currentThread.getContextClassLoader

    require "./jobs/tasks/message_replay/lib/messaging.jar"

    jars = Dir.glob("./jobs/tasks/message_replay/lib/*.jar")
    jars.each do |jar|
      #require jar #whle this line will work if the jars have any other resources (like .property files) You must do...
      #$logger.debug("Adding in jar #{jar}")
      @my_class_loader.addURL(jar)#if you have resources in your jars use this instead.
    end
    bd = @my_class_loader.loadClass('gov.va.med.caip.client.factory.BusinessDelegateFactory')
    $logger.debug("The business delegate is " + bd.toString)

    java_import 'gov.va.med.datasharing.common.messaging.transformer.xml.StringToXML' do |pkg, cls|
      'JStringToXML'
    end

    java_import 'gov.va.med.datasharing.core.ServiceBus'
    java_import 'org.springframework.context.support.ClassPathXmlApplicationContext' do |pkg, cls|
      'JClasspathXmlApplicationContext'
    end

    java_import 'org.springframework.core.io.DefaultResourceLoader' do |pkg, cls|
      'JDefaultResourceLoader'
    end

    java_import 'org.springframework.context.support.GenericApplicationContext' do |pkg, cls|
      'JGenericApplicationContext'
    end

    @transformer = JStringToXML.new
  end

  def post_init
    success = false
    begin
      @spring_xml = [@spring_beans_path]
      process_additional_args if respond_to? :process_additional_args
      @replay_count = 0
      begin
        jdrl = JDefaultResourceLoader.new(@my_class_loader)
        jgac = JGenericApplicationContext.new
        jgac.setResourceLoader(jdrl)
        @context = JClasspathXmlApplicationContext.new
        @context.setConfigLocations(@spring_xml)
        @context.setParent(jgac)
        jgac.refresh
        @context.refresh
      rescue => ex
        $logger.error(ex.to_s)
        $logger.error(ex.backtrace.join("\n"))
      end
      $logger.info(@context.to_s)
      @service_bus = @context.getBean("serviceBusBean")
      $logger.info("Got me a service bus!!! " + @service_bus.to_s)
      job_specific_init if respond_to? :job_specific_init
      success = true
    rescue => ex
      $logger.info(ex.to_s)
      $logger.info(ex.backtrace.join("\n"))
      $logger.info("****" + @spring_beans_path)
    end
    success
  end

  def get_replay_message_id(message_id)
    msg_parts_array = get_replay_message_parts(message_id)

    #return the message_id with the replay indicator and index
    msg_parts_array[0] + $REPLAY_LABEL + msg_parts_array[1].to_s
  end

  def get_replay_message_parts(message_id)
		count = 1

    #check the message id to see if it has been replayed previously
    message_parts = message_id.split($REPLAY_LABEL)
		msg_id = JSystem.nanoTime.to_s($RADIX) + $message_id_tag

    #increment the replay count for the new replay message
		unless (message_parts[1].nil?)
    	count = message_parts[1].to_i + 1
		end

    [msg_id, count]
  end

  def get_replay_count(message_id)
    get_replay_message_parts(message_id)[1]
  end

  def replay_results(html = true)
    start = @start_date.strftime("%Y%m%d")
    finish = @end_date.strftime("%Y%m%d")
    success, failure, no_replay = [0,0,0]

    @tracking_hash[:replay].each_pair do |message_id,data_array|
      success += 1 if data_array.last == $REPLAY_SUCCESS
      failure += 1 if data_array.last == $REPLAY_FAILURE
      no_replay += 1 if data_array.last == $REPLAYED_PREVIOUSLY
    end

    html_template = <<-htm
      <br><br>
      <div style="width: 980px; border-style: solid; border-width:thin; font-size: 12px; padding-left: 10px">
          <h2>Replay Results from #{start} to #{finish}</h2>
          <table valign="top">
              <tr><td align="right" width="170px">ResultSet Returned:</td><td align="left">#{@sql_result_row_count.to_s}</td></tr>
              <tr><td align="right" width="170px">Successful Replays:</td><td align="left">#{success.to_s}</td></tr>
              <tr><td align="right" width="170px">Failed Replays:</td><td  align="left">#{failure.to_s}</td></tr>
              <tr><td align="right" width="170px">Replayed Previously:</td><td  align="left">#{no_replay.to_s}</td></tr>
          </table>
      </div>
    htm
    text_template = <<-txt
      \n\n\n
      Replay Results from #{start} to #{finish}\n\n
      \tResultSet Returned: #{@sql_result_row_count.to_s}\n
      \tSuccessful Replays: #{success.to_s}\n
      \tFailed Replays: #{failure.to_s}\n
      \tReplayed Previously: #{no_replay.to_s}\n\n
    txt

    html ? html_template : text_template
  end

  def track_faults(fault_code, fault_detail)
    @tracking_hash[:fault_details] = {} if @tracking_hash[:fault_details].nil?
    @tracking_hash[:fault_details][fault_code] = {} if @tracking_hash[:fault_details][fault_code].nil?

    if @tracking_hash[:fault_details][fault_code][fault_detail].nil?
      @tracking_hash[:fault_details][fault_code][fault_detail] = 1
    else
      @tracking_hash[:fault_details][fault_code][fault_detail] += 1
    end
  end

  def track_fault_results(html = true)
    html_template = <<-htm
      <br><br>
      <div style="width: 980px; border-style: solid; border-width:thin; font-size: 12px; padding-left: 10px; padding-right: 10px">
        <h2>Top #{@top_fault_count} Faults by Fault Code</h2>
        <table class="display"><tr><th>Fault Code</th><th>Count</th><th style="text-align: center">Fault Detail</th></tr>
        FAULT_DETAILS
        </table>
      </div>
      <br><br>
    htm

    text_template = <<-txt
      \n\n
      Top #{@top_fault_count} Faults by Fault Code\n
      FAULT_DETAILS
      \n\n
    txt

    results = html ? "<br>" : "\n"
    return results + "No fault data" if @tracking_hash[:fault_details].nil?
    details = ""

    @tracking_hash[:fault_details].each_pair do |fault_code,fault_detail_hash|
      cloned_hash = fault_detail_hash.clone
      ordered_array = cloned_hash.to_a.sort{|a,b| b[1] <=> a[1]}
      top_fault_countdown = ordered_array[0..@top_fault_count-1]
      cnt = 0

      top_fault_countdown.each do |e|
        cnt += 1
        odd_even = (cnt % 2) == 1 ? "odd" : "even"
        details += html ? "<tr class=\"#{odd_even}\"><td>#{fault_code}</td><td>#{e[1]}</td><td style=\"text-align: left; padding-left: 10px\">#{e[0]}</td></tr>" : "Fault Code #{fault_code} COUNT is #{e[1]} for :: #{e[0]}\n"
      end
    end
    html ? html_template.gsub("FAULT_DETAILS", details) : text_template.gsub("FAULT_DETAILS", details)
  end

  def format_tracking_results_for_all_errors(tracking_sym, label, html = true)
    result = ""
    @tracking_hash[tracking_sym].each_pair { |k, v|
      result += "#{label}: #{k} count: #{v.to_s} #{html ? "<br>" : "\n"}"
    }
    result
  end

  def transform_to_dom(message_id, xml_content)
    dom = nil

    begin
      message = assign_message_id(xml_content, message_id)
      dom = @transformer.transform(message)
    rescue => ex
      @tracking_hash[:transform_errors] << message_id + " :: " + ex.to_s
    end
    $logger.debug("dom is returning nil for message id " + message_id + "\n********\n" + xml_content) if dom.nil?
    dom
  end

  def format_transform_errors(html = true)
    result = html ? "<br>" : "\n"
    result += "Transformation Errors:#{html ? "<br>" : "\n"}"
    result += "#{html ? "&nbsp;&nbsp;&nbsp;" : "\n"}None" if @tracking_hash[:transform_errors].size == 0

    @tracking_hash[:transform_errors].each { |message_id|
      result += "Transform Error Message Id: #{message_id} #{html ? "<br>" : "n"}"
    }

    result += html ? "<br><br>" : "\n\n"
    result
  end

  def service_bus_termination_message(html = true)
    ret = ""

    if @service_bus_error_count >= @max_service_bus_errors
      ret = html ? "<span style=\"font-weight: bold; font-size: 20px\">" : ""
      ret += "Service Bus Went Down! Attempted #{@service_bus_error_count} Service Bus calls that failed. Job terminated prematurely. Re-run as a service"
      ret += html ? "</span>" : ""
    end
    ret
	end

  def max_replay_termination_message(html = true)
		ret = ""
		if (@display_max_termination_message)
			ret = html ? "<span style=\"font-weight: bold; font-size: 20px\">" : ""
			ret += "Maximum number of replay messages reached. Successfully replayed #{@replay_max}. Job terminated prematurely. Re-run as a service"
			ret += html ? "</span>" : ""
		end
		ret
  end
end
