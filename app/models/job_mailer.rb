class JobMailer < ActionMailer::Base
  def job_result (email_hash, sent_at = Time.now) #this method is invoked by a job engine thread and part of the thread pool
    email_hash[:unique_mail_id] = JobMailer.get_unique_message_id
    mail_hash = {:subject => email_hash[:subject], :to => email_hash[:recipients],
                 :from => email_hash[:from], :cc => email_hash[:cc], :date => sent_at}

    #see email_hash[:body] for the body
    @jle = email_hash[:jle]
    @jmd = email_hash[:jmd]
    @sent_on = sent_at
    @body = email_hash[:body]
    mail_hash[:subject].gsub!("\r","") #unstructed_field.rb at line 179 is putting garbage in the subject line if we don't do this
    $logger.info('sending the email with ID ' << email_hash[:unique_mail_id].to_s)
    $logger.info("The email's subject is " << email_hash[:subject].to_s)
    $logger.info("The email's to list is " << email_hash[:recipients].to_s)
    $logger.info("The email's cc list is " << email_hash[:cc].to_s)
    unless  email_hash[:sending_cached_result]
      job_log_entry = email_hash[:jle]
      job_log_entry.email_sent = true
      past_email = job_log_entry.email_to
      job_log_entry.email_to = email_hash[:recipients]
      job_log_entry.email_to << ',' << past_email unless past_email.nil?
      job_log_entry.email_cc = email_hash[:cc]
    end
    filename = nil
    if (email_hash[:incl_attachment])
      filename = email_hash[:attachment_path].split('/').last
      filename = 'unknown.txt' if filename.eql?('')
      file = nil
      begin
        file = File.read(email_hash[:attachment_path])
      rescue => ex
        $logger.error("Could not attach the file for e-mailing! " << ex.to_s)
      end
    end
    $db_lock.synchronize {
      begin
        job_log_entry.save(:validate => false) unless  email_hash[:sending_cached_result]
        unless (Thread.current[:sending_cached_result] || email_hash[:sending_cached_result])
          jmd = email_hash[:jmd]
          jmd.last_email_sent = Time.now
          jmd.save(:validate => false)
        end
      rescue => e
        $logger.error(e.backtrace.join("\n"))
      end
    }
    attachments[filename] = file unless file.nil?
    mail(mail_hash) do |format|
      format.text unless @jmd.email_content_type.eql?('text/html')
      format.html if @jmd.email_content_type.eql?('text/html')
    end
  end

  def oracle_unreachable(request, connect_array, sent_at = Time.now)
    the_body = "The CHDR database connection state is: "
    state = (connect_array[0] ? 'connected' : 'unreachable')
    the_body << state << ".\n"
    $logger.error("oracle_unreachable e-mail sent with state #{state}")
    the_body << ". Request #{request} is not being executed!\nThe error message is: #{connect_array[1]}" unless connect_array[0]
    recipients = $application_properties['PST_Team']
    subject = "CHDR Oracle is #{state}"
    from = $application_properties['PST_Team']
    @body = the_body
    @sent_on = sent_at
    mail({:subject => subject, :to => recipients, :from => from, :date => sent_at})
  end

  def database_credential_ceased_working(oracle_id, exception, sent_at = Time.now)
    the_body = "The current oracle credential (#{oracle_id}) ceased working!\n"
    the_body << "The exception is:  " << exception.to_s
    $logger.error("database_credential_ceased_working e-mail sent with ID #{oracle_id} and exception " << exception.to_s)
    recipients = $application_properties['PST_Team']
    subject = "Update SHAMU credentials!"
    from = $application_properties['PST_Team']
    @body = the_body
    @sent_on = sent_at

    mail({:subject => subject, :to => recipients, :from => from, :date => sent_at})
  end

  def credentials_not_seeded(request, sent_at = Time.now)
    recipients = $application_properties['PST_Team']
    subject = 'Job execution engine needs oracle credentials!'
    from = $application_properties['PST_Team']
    @body = "Job execution engine needs oracle credentials!  Request #{request} is not being executed!"
    @sent_on = sent_at

    attachments["shamu_quartz.zip"] = File.read("/tmp/shamu_quartz.zip")


    mail({:subject => subject, :to => recipients, :from => from, :date => sent_at})
  end

  private
  @@lock = Mutex.new
  @@count=0

  def self.get_unique_message_id
    @@lock.synchronize {
      @@count = @@count+1
      Time.now.to_s << '__' << @@count.to_s
    }

  end

end
