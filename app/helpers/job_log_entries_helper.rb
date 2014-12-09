module JobLogEntriesHelper
  def formatEmailedOnList(email_to, email_cc)
    arr_email_to = []
    arr_email_cc = []
    arr_email_to = email_to.split(',') unless email_to.nil?
    arr_email_cc = email_cc.split(',') unless email_cc.nil?
    emails = (arr_email_to | arr_email_cc).uniq
    emails.join(', ')
	end

	def get_job_code_filter_options
		if (session[:job_log_search][:filter_by_job_status].to_sym.eql?(:STATUS_CHANGE_ONLY) ||
				session[:job_log_search][:filter_by_job_status].to_sym.eql?(:ESCALATION_CHANGE_ONLY) ||
				session[:job_log_search][:filter_by_job_status].to_sym.eql?(:ALERTS_ONLY))
			options = @trackable_jmds
		else
			if (session[:job_log_search][:filter_by_job_status].to_sym.eql?(:NON_ALERTS_ONLY))
				options = @non_trackable_jmds
			else
				options = @job_code_filter
			end
		end
		options
	end
end
