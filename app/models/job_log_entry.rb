require 'monitor'
require 'helpers'
class JobLogEntry < ActiveRecord::Base
  scope :get_log_entries, lambda {|days_old| {:conditions => ["start_time > ?", Time.now - days_old.days], :order => 'start_time desc'} }
  scope :max_finish_for_job_code, lambda {|job_code| {:conditions => ['job_code = ? and finish_time IS NOT NULL', job_code], :order => 'finish_time desc'} }
  scope :limit, lambda {|num| {:limit => num } }

  scope :last_tracked_status, lambda {|jc, status_known| job_code(jc).finished(true).tracked(status_known).order("finish_time desc").limit(1) }
  scope :last_tracked_status_change, lambda {|jc, status_known| job_code(jc).finished(true).tracked(status_known).status_changed(true).order("finish_time desc").limit(1) }
  scope :job_code, lambda {|jc| where("job_code = ?", jc)}
  scope :email_sent, lambda {|bool| {:conditions => ['email_sent = ?', bool]} }

  scope :user_jobs, lambda {|job_code| {:conditions => ['job_code = ? and run_by != ?', job_code, 'SYSTEM'] } }
  scope :started_within, lambda {|time| {:conditions => ["start_time > ?", time] } }

  scope :job_log_by_jc_desc, lambda {|job_code| {:conditions => ['job_code = ?', job_code], :order => 'start_time desc' } }
  scope :finished, lambda {|bool| where(bool ? "finish_time IS NOT NULL" : "finish_time IS NULL")  }
  scope :status_completed, lambda {|bool| {:conditions => (bool ? "run_status = 'Completed'" : "run_status != 'Completed'")} }
  scope :status_changed, lambda {|bool| {:conditions => ["status_changed = ?", bool] } }

  scope :status_not, lambda {|status| {:conditions => ["status != ?", status] } }
  scope :before, lambda {|jle| {:conditions => ["id < ? and job_code = ?", jle.id, jle.job_code], :order => 'id desc' } }
  scope :after, lambda {|jle| {:conditions => ["id > ? and job_code = ?", jle.id, jle.job_code], :order => 'id asc' } }
  scope :after_inclusive, lambda {|jle| {:conditions => ["id >= ? and job_code = ? and status != 'UNKNOWN'", jle.id, jle.job_code], :order => 'id asc' } }

  scope :tracked, lambda {|bool| where(bool ? "status in ('RED','GREEN')" : "( status is null or status = 'UNKNOWN' )") }




  #belongs_to :job_metadata, :foreign_key => :job_code

  @@xml_template = Utilities::FileHelper.file_as_string('./config/IntroscopeAlerts.xml.template')

  #  scope :log_entry_desc, lambda { |jc| { :conditions => {:last, ["job_code = ?",jc]} } }

  #return nil if jle has a status of green
  def get_escalation
     escalations = JobMetadata.job_code(job_code)[0].escalations
   # escalations = self.job_metadata.escalations
    if finish_time.nil?
    	$logger.error("JobLogEntry.get_escalation called on a running job!")
    	raise "Illegal to call this method on a running job!" if finish_time.nil?
    end

    return nil unless (status.eql?('RED'))
    first_red_jle = JobLogEntry.get_jle_in_sequence(self, :before, true)
    start = self.finish_time
    start = first_red_jle.finish_time unless (first_red_jle.nil? || !first_red_jle.status.eql?("RED"))
    finish = self.finish_time
    elapsed_seconds = finish - start
    escalations.each do |esc|
    	return esc if (esc.end_min.nil?) #handle red
    	return esc if (esc.enabled && ((esc.end_min*60) - elapsed_seconds) >= 0)
    end
    $logger.error("No escalation was found for this red job #{jle.job_code}")
  end

  def self.delete_jles(job_code)
    num = JobLogEntry.delete_all(['job_code = ?', job_code])
    num = num.to_s
    puts "#{num} job log entries deleted!"
  end

  def get_email_hash
    body = ''
    subject = ''
    hash = {}
    if (self.job_result =~ /.*EMAIL_RESULT_BELOW:(.*)EMAIL_RESULT_ABOVE:.*/m)
      body = $1
      body =~ /SUBJECT:(.*)/
      subject = $1
      body.sub!("SUBJECT:#{subject}",'')
      hash[:body] = body
      hash[:subject] = subject << " -- (cached result)" unless subject.nil?
      hash[:subject] = "NO subject -- (cached result)" if subject.nil?
    else
      return nil
    end
     hash[:jmd] = JobMetadata.job_code(self.job_code)[0]
     hash[:content_type] = hash[:jmd].email_content_type
     hash[:sending_cached_result] = true
    hash
  end

  def self.is_user_job_running?(job_code)
    jl = JobLogEntry.user_jobs(job_code)
    jl = jl.finished(false)
    jl = jl.started_within($application_properties['job_runaway_after'].to_i.minutes.ago)
    return !jl.empty?
  end

  def self.is_named_job_running?(job_code)
    jl = JobLogEntry.job_code(job_code)
    jl = jl.finished(false)
    jl = jl.started_within($application_properties['job_runaway_after'].to_i.minutes.ago)
    return !jl.empty?
  end

  def self.get_last_tracked_status(job_code, status_known)
    #JobLogEntry.job_code2(job_code).finished2(true).last_tracked_status2(status_known).order('finish_time desc').limit(1)
    JobLogEntry.last_tracked_status(job_code,status_known)[0]
  end

  def self.test_tracked
    jle = JobLogEntry.get_last_tracked_status('NO_DOD_TRAFFIC', false)
    puts "The job is #{jle.inspect}"
    jle = jle[0]
    puts "The JobMetadata is #{jle.inspect}"
  end

  def self.search(criteria_hash, date_range, page)
    job_code = criteria_hash[:filter_by_job_code]
    job_code = '' if (job_code.nil? || job_code.eql?('ALL'))
    condition = '1=? '
    args = []

    if (! job_code.eql?(''))
      condition = "job_code = ? "
      args.push(job_code)
    else
      args.push(1)
    end

    if (date_range[0].nil? && date_range[1].nil?)
      # do nothing
      return []
    elsif (date_range[0].nil? && ! date_range[1].nil?)
      condition << " and finish_time < ?"
      args.push(date_range[1])
    elsif (! date_range[0].nil? && date_range[1].nil?)
      condition << " and (finish_time > ? or finish_time is null)"
      args.push(date_range[0])
    else
      condition << " and finish_time between ? and ?"
      args.push(date_range[0])
      args.push(date_range[1])
		end

    condition_no_criteria = condition.clone
    args_no_criteria = args.clone
    job_status = criteria_hash[:filter_by_job_status].to_sym

    unless job_status.eql?(:NO_FILTER)
      case job_status
        when :STATUS_CHANGE_ONLY, :ESCALATION_CHANGE_ONLY then
          condition << " and run_status = ? and status_changed = ?"
          args.push("Completed")
          args.push(true)
        when :RUNNING_JOBS_ONLY then
          condition << " and (run_status = ? or run_status = ?)"
          args.push("Running")
          args.push("Pending")
        when :EMAILED_JOBS_ONLY then
          condition << " and email_sent = ?"
          args.push(true)
				when :ALERTS_ONLY,:NON_ALERTS_ONLY then
					if (job_code.eql?(''))
						condition << " and job_code in (?)"
						args.push(job_status.eql?(:ALERTS_ONLY) ? criteria_hash[:alert_only_in] : criteria_hash[:non_alert_only_in])
					end
        else
          #run by the current user
          condition << "and run_by = ?"
          args.push(job_status.to_s)
      end
		end

    condition_array = [condition]

    if (job_status.eql?(:ESCALATION_CHANGE_ONLY))
      status_changes = JobLogEntry.all(:conditions => condition_array.concat(args), :order => 'start_time desc')
      no_filter_results = JobLogEntry.all(:conditions => [condition_no_criteria].concat(args_no_criteria), :order => 'start_time desc')
      return [status_changes,no_filter_results]
    end

    JobLogEntry.all(:conditions => condition_array.concat(args), :limit => criteria_hash[:filter_limit], :order => 'start_time desc')
  end

  def self.is_job_running? ()
    jl = JobLogEntry.finished(false)
    $logger.info("There are " << jl.size.to_s << " not complete jobs")
    jl = jl.started_within($application_properties['job_runaway_after'].to_i.minutes.ago)
    $logger.info("There are " << jl.size.to_s << " not complete and not runaway jobs")
    #jl = jl.started_within(10.minutes.ago)
    #   $logger.info("There are " << jl.size.to_s << " 10 min not complete and not runaway jobs")
    $logger.info("!Empty? " << (!jl.empty?).to_s)
    return !jl.empty?
  end

  def self.get_last_completed(job_code)
    @jle = JobLogEntry.max_finish_for_job_code(job_code)
    @jle2 = @jle.limit(1)
    return @jle2[0]

    #jl = JobLogEntry.find(:all, :conditions => ['job_code = ?', jmd.job_code], :order => 'finish_time desc') #this returns a time not the jle
    #return nil # getting this: undefined method `finish_time' for Thu Jan 28 04:42:49 UTC 2010:Time
    # return !jl.nil? && !jl.finish_time.nil? && (Time.now + jmd.stale_after_min.minutes >= jl.finish_time) ? jl : nil
  end

  def self.set_old_status_changes
    puts "In set old status change..."
    trackables=JobEngine.instance.get_trackable_jobs
    trackables.each do |trackable|
      jles = JobLogEntry.job_code(trackable.job_code).reverse
      last_status = nil
      current_status = nil
      jles.each do |jle|
        current_status = jle.status
        next if current_status.eql?('UNKNOWN')
        if (!last_status.nil? && !current_status.eql?(last_status))
          jle.status_changed = true
          jle.save(:validate => false)
          puts "Status change on job -- #{jle.inspect}"
        end
        last_status = current_status
      end
    end
  end

  def self.rename_job_code(old_name,new_name)
    puts "Did you remember to stop the job engine?  Enter y to continue"
    STDOUT.flush
    user_input = $stdin.gets
    user_input.chomp!
    if (user_input.eql?('y'))
      puts "job_code = '#{new_name}', job_code = '#{old_name}'"
      changed = JobLogEntry.update_all("job_code = '#{new_name}'","job_code = '#{old_name}'")
      puts "records changed = " << changed.to_s
    end
  end

  def self.delete_job_code(job_code)
    puts "Did you remember to stop the job engine?  Enter y to continue"
    STDOUT.flush
    user_input = gets
    user_input.chomp!
    if (user_input.eql?('y'))
      changed = JobLogEntry.delete_all("job_code = '#{job_code}'")
      puts "records changed = " << changed.to_s
    end
  end

  def self.clean_up_log(days_old=90)
    num =JobLogEntry.delete_all(['finish_time < ?', Time.now - days_old.to_i.days])
    num.to_s
  end

  def self.clean_up_log_for_user
    puts "Trim everything older than how many days?  Enter for the default of 90."
    days_back = $stdin.gets
    days_back.chomp!
    days_back = "90" if days_back.eql? ""
    days_back = days_back.to_i
    return if (days_back == 0)
    puts "About to trim the database"
    trimmed = JobLogEntry.clean_up_log days_back
    puts "Done!  I trimmed #{trimmed} records from the database!"
  end

  def self.destroy_log()
    JobLogEntry.delete_all('1=1')
  end

  def self.introscope_alerts()
    xml_output = ""
    color_codes = $application_properties['introscope_colors'].split(',')
    color_to_code = {}
    color_codes.each do
      |cc|
      color, code = cc.split("=>")
      color_to_code[color.strip.upcase] = code.strip
    end

    @trackables = JobEngine.instance.get_trackable_jobs
    return if (@trackables.nil? or @trackables.length == 0)
    @trackables.each do |trackable|
      if (trackable.introscope_enabled)
        xml = @@xml_template.clone
        status_change_jle = JobLogEntry.get_last_tracked_status_change(trackable.job_code)
        next if status_change_jle.nil? #this job has never run
        epoch_time = status_change_jle.finish_time.to_i * 1000
        xml.gsub!('START_TIME_DATE',epoch_time.to_s)
        xml.gsub!('JOB_CODE', trackable.use_introscope_job_code ? trackable.introscope_job_code : trackable.job_code)
        short_desc = trackable.use_introscope_short_desc ? trackable.introscope_short_desc : trackable.short_desc
        #short_desc.gsub!("\n","   ")
        long_desc = trackable.use_introscope_long_desc ? trackable.introscope_long_desc : trackable.desc
        #long_desc.gsub!("\n","   ")
        xml.gsub!('SHORT_DESCRIPTION',short_desc.nil? ? '' : short_desc)
        xml.gsub!('LONG_DESCRIPTION',long_desc.nil? ? '' : long_desc )
        xml.gsub!('IS_ACTIVE',trackable.active ? "1" : "0") #active will be 1 inactive will be 0
        jle = trackable.get_last_log_entry_with_status("Completed")
        escalation = jle.get_escalation
        status = nil
        if (jle.status.eql?("UNKNOWN"))
          status = color_to_code["UNKNOWN"]
        else
          if (escalation.nil?)
            status = '1' #green
          else
            status = color_to_code[escalation.color_name]#jle.status.eql?('GREEN') ? 1 : jle.status.eql?("RED") ? 2 : 3 #green is 1 red is 2 unknown is three
            status = '0' if status.nil? # catch all in case the administrator is mildly retarded and neglects to properly define 'introscope_colors' in our application properties file.
          end
        end
        xml.gsub!('STATUS_RED_GREEN',status.to_s)
        epoch_time = jle.finish_time.to_i * 1000
        xml.gsub!('LAST_COMPLETED_DATE',epoch_time.to_s)#convert to a format java.util.Date.parse can handle (required by introscope)
        xml.gsub!('TRACKABLES_PAGE',$application_properties['root_url'] + $application_properties['trackables_path'])
        xml.gsub!('JOB_LOG_ENTRY_PAGE',$application_properties['root_url'] + $application_properties['job_log_entry_path'] + '/' + jle.id.to_s)
        xml.gsub!('EVENT_ID',jle.id.to_s)
        xml.gsub!(/EVENT_PROPERTIES_EXPANSION(.*)EVENT_PROPERTIES_EXPANSION/) {
          |the_string|
          match = $1
          if jle.introscope_data.nil?
            ""
          else
            the_string = ''
            data_array = jle.introscope_data.split(';')
            data_array.each { |elem|
              match_l = match.clone
              key_values = elem.split('=')
              match_l.gsub!('EVENT_KEY',key_values[0])
              match_l.gsub!('EVENT_VALUE',key_values[1])
              the_string << match_l << "\n"
            }
            the_string
          end
        }
        xml_output << xml
      end
    end
    #iterate over introscope trackables and gsub appropriately...
    xml_output
  end

  #    JobLogEntry.job_code(job_code).finished(true).last_tracked_status(status_known).limit(1)
  def self.get_last_tracked_status_change(job_code)
    return nil unless  JobMetadata.job_code(job_code)[0].track_status_change
    jle = JobLogEntry.last_tracked_status_change(job_code,true)[0]
    jle = JobLogEntry.job_log_by_jc_desc(job_code).tracked(true).last if jle.nil?
    jle
  end

=begin
  def self.get_jle_in_sequence2(jle, older = false, status_change_only = false)
#    return nil unless JobMetadata.job_code(jle.job_code)[0].track_status_change
    begin
    	initial_jle = nil

    	if (status_change_only)
    		initial_jle = JobLogEntry.before(jle).finished(true).status_changed(true) if older
    		initial_jle = JobLogEntry.after(jle).finished(true).status_changed(true) unless older
    	else
    		initial_jle = JobLogEntry.before(jle).finished(true) if older
    		initial_jle = JobLogEntry.after(jle).finished(true) unless older
    	end

      initial_jle = initial_jle[0]
    rescue => ex
      return nil
    end
    initial_jle
  end
=end

  #let scope = :before or :after
  def self.get_jle_in_sequence(jle, scope, status_change_only = false)
#    return nil unless JobMetadata.job_code(jle.job_code)[0].track_status_change
    begin
      if (JobMetadata.job_code(jle.job_code)[0].track_status_change)
        if (status_change_only)
          initial_jle = JobLogEntry.send(scope,jle).status_not("UNKNOWN").finished(true).status_changed(true).limit(1)
        else
          initial_jle = JobLogEntry.send(scope,jle).status_not("UNKNOWN").finished(true).limit(1)
        end
      else
        initial_jle = JobLogEntry.send(scope,jle).finished(true).limit(1)
      end
      initial_jle = initial_jle[0]
    rescue => ex
      return nil
    end
    initial_jle
  end

  def self.get_last_email_sent_jle(job_code)
    emails = JobLogEntry.job_code(job_code).email_sent(true)
    no_emails = JobLogEntry.job_code(job_code).email_sent(false).status_changed(true)
    puts "We have found " + emails.length.to_s + " entries!"
    puts "We have found (no_emails status changes) " + no_emails.length.to_s + " entries!"
    puts "The first finished at " + no_emails.first.finish_time.to_s
    puts "The last finished at " + no_emails.last.finish_time.to_s
    last_email_sent_jle = JobLogEntry.after(emails.first).email_sent(true)
    puts "last_email_sent_jle = " + last_email_sent_jle[0].finish_time.to_s
  end
end
#/home/t192zcs/Aptana_Studio_Workspace/PSTDashboard/script/runner -e development "JobLogEntry.destroy_log"
#/home/t192zcs/Aptana_Studio_Workspace/PSTDashboard/script/runner -e development "app/models/job_log_entry.rb"
#JobLogEntry.destroy_log
