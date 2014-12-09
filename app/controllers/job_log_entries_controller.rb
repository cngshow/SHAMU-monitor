require 'time_utils'

class JobLogEntriesController < ApplicationController
  skip_before_filter :login_required
  def list
    $logger.debug("***************************** in list of jle controller *****************************")
    searching = ! params[:commit].nil? && params[:commit].eql?("Search")
		@jmds = JobEngine.instance.get_job_meta_datas
    @job_code_filter = @jmds.map{|jmd| jmd.job_code}
    @job_code_filter.unshift("ALL")

		@trackable_jmds = JobEngine.instance.get_trackable_jobs
		@trackable_jmds = @trackable_jmds.map{|jmd| jmd.job_code}
		@trackable_jmds.unshift('ALL')

		@non_trackable_jmds = @job_code_filter - @trackable_jmds
		@non_trackable_jmds.unshift('ALL')

    @job_status_filter = [["---No Filter---", :NO_FILTER], ["Status Change Only", :STATUS_CHANGE_ONLY],["Escalation Change Only", :ESCALATION_CHANGE_ONLY], ["Running Jobs Only", :RUNNING_JOBS_ONLY], ["E-Mailed Jobs Only", :EMAILED_JOBS_ONLY],["Alerts Only", :ALERTS_ONLY],["Non-Alerts Only", :NON_ALERTS_ONLY]]
    @job_status_filter.push(["Jobs Run By User: #{current_user.login}", current_user.login.to_sym]) unless current_user.nil?

    session[:job_log_search] = Hash.new if session[:job_log_search].nil?
    session[:job_log_search][:filter_by_job_code] = params[:filter_by_job_code] if searching
    session[:job_log_search][:filter_by_start_date] = params[:filter_by_start_date] if searching
    session[:job_log_search][:filter_by_finish_date] = params[:filter_by_finish_date] if searching
    session[:job_log_search][:filter_by_job_status] = params[:filter_by_job_status] if searching
    session[:job_log_search][:filter_limit] = params[:filter_limit] if searching
    session[:job_log_search][:filter_by_job_status] = :ALL if session[:job_log_search][:filter_by_job_status].nil?

    @outage_hunting = session[:job_log_search][:filter_by_job_status].to_sym.eql?(:STATUS_CHANGE_ONLY)
    @escalation_hunting = session[:job_log_search][:filter_by_job_status].to_sym.eql?(:ESCALATION_CHANGE_ONLY)
    
    if (session[:job_log_search][:filter_by_start_date].nil? || session[:job_log_search][:filter_by_start_date].eql?(''))
      session[:job_log_search][:filter_by_start_date] = days_back_to_date_string($application_properties['jle_default_start_search'])
    end

    session[:job_log_search][:filter_by_finish_date] = '' if session[:job_log_search][:filter_by_finish_date].nil?
		session[:job_log_search][:alert_only_in] = @trackable_jmds
		session[:job_log_search][:non_alert_only_in] = @non_trackable_jmds

    @time_zone_string = TimeUtils.offset_to_zone(session[:tzOffset])
    @offset = session[:tzOffset]
    @date_range = convert_dates(session[:job_log_search][:filter_by_start_date], session[:job_log_search][:filter_by_finish_date])

		#execute the search
    @job_log_entries = JobLogEntry.search(session[:job_log_search], @date_range, params[:page])

    $logger.debug("jle count" + @job_log_entries.length.to_s)
    
    if (@outage_hunting || @escalation_hunting)
      alert_array = calculate_and_order_alert_times(@job_log_entries) if @outage_hunting
      alert_array = escalation_changes_only(@job_log_entries) if @escalation_hunting
      @alert_times = alert_array[0]
      @job_log_entries = alert_array[1]
    end

    @job_log_entries_page = WillPaginate::Collection.create(params[:page].nil? ? 1 : params[:page].to_i, 12,@job_log_entries.size) do |pager|
      pager.replace @job_log_entries[pager.offset, pager.per_page].to_a
    end

    @page_hdr = "Job Log Entry Listing"
    session[:jle_list_refresh] = false if session[:jle_list_refresh].nil?

    @page_nav = [{:label => 'Trackables', :route => trackables_path}]
    if (current_user)
      @page_nav.push({:label => "Auto Refresh: #{(session[:jle_list_refresh] ? 'On' : 'Off')}",:route => job_log_list_refresh_path, :confirm => "Are you sure you want to turn auto-refresh #{(session[:jle_list_refresh] ? 'Off' : 'On')}?"})
      @page_nav.push({:label => 'Job Listing', :route => job_metadatas_list_path}) if admin_check?
    end

    respond_to do |format|
      format.html #list.html.erb
      format.xml  { render :xml => @job_log_entries }
    end
  end

  def auto_refresh
    session[:jle_list_refresh] = ! session[:jle_list_refresh]
    redirect_to job_log_list_path
  end

  def show
    @job_log_entry = JobLogEntry.find(params[:id])
    jc = @job_log_entry.job_code
    @jmd = JobMetadata.job_code(jc)[0]
    @page_hdr = "Job Log Listing for:  " + jc
    @page_nav = [{:label => 'Back to Job Log', :route => job_log_list_path}]
    @page_nav.push({:label => 'Back To Trackables', :route => trackables_path}) if @jmd.track_status_change
    @page_nav.push({:label => "Edit Job", :route => job_metadatas_edit_path(@jmd.id)}) if admin_check?

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @job_log_entry }
    end
  end

  def email_user
    raise "You are not logged in!" if current_user.nil?
    @job_log_entry = JobLogEntry.find(params[:id])
    email_hash = @job_log_entry.get_email_hash
    unless email_hash.nil?
      email_hash[:recipients] = current_user.email
      email_hash[:from] = $application_properties['PST_Team']
      email_hash[:jle] = @job_log_entry
      $logger.info("Preparing to send cached result from controller") 
      my_task = lambda do |tag,jle|
         JobMailer.job_result(email_hash).deliver
         $logger.info("Cached result sent!") 
      end
      @@request_pool.dispatch(my_task,"CACHED_EMAIL", "cached email", @job_log_entry)
    end
    flash[:notice]= "Result sent to " << current_user.email unless email_hash.nil?
    flash[:error] = "Job Result is not e-mailable!" if email_hash.nil?
    redirect_to(job_log_entry_path(@job_log_entry))
  end

  private

  def days_back_to_date_string(days_string)
    date_components = days_string.to_i.days.ago.to_s.split(/\s+/)[0].split(/-/)
    date_components[1]+'/' + date_components[2] + '/' + date_components[0]
  end

  def convert_dates(start, finish)
    start = '' if start.nil?
    finish = '' if finish.nil?
    return [nil,nil] if (start.eql?('') && finish.eql?(''))

    begin
      start_time = Time.parse(start + ' ' + @time_zone_string).utc
      finish_time = Time.parse(finish + ' ' + @time_zone_string).utc
      now = Time.now.utc
      if (start_time > now || finish_time > now)
        flash.now[:error] = "The start time nor the finish time can in the future!"
        return [nil,nil]
      end
      if (!start.eql?('') && (start_time > finish_time))
        flash.now[:error] = "Start time must be earlier than the finish time!"
        return [nil,nil]
      end

			start_time = nil if start.eql?('')
			finish_time = nil if finish.eql?('')
    rescue
      flash.now[:error] = "The start and finish dates must be entered in following format: mm/dd/yy hh24:mm or mm/dd/yy."
      return [nil,nil]
    end
    [start_time,finish_time]
  end

  def calculate_and_order_alert_times(jles, as_pairs = false)
    #to get a well formed jle array of alert period jles the pattern must be G,R,G,R,G,R
    #So, as this array is ordered from youngest to oldest, the youngest element, if red, must be removed as it implies
    #that the user's date range stripped off the (even younger) clearing alert.  Similarly, the last element must be red!
    jles = valid_alert_pairs_only(jles)

    alert_hash = Hash.new
    jles.reverse!
    jles.each do |jle|
      alert_hash[jle.job_code] = Hash.new if alert_hash[jle.job_code].nil?
      alert_hash[jle.job_code][:red] = [] unless alert_hash[jle.job_code].has_key?(:red)
      alert_hash[jle.job_code][:green] = [] unless alert_hash[jle.job_code].has_key?(:green)
      if jle.status.eql?('UNKNOWN')
        #should never happen.  Debug if you see this
        $logger.error("calculate_alert_times: Found a jle with status of UNKNOWN.  This is IMPOSSIBLE!")
        raise "JobLogEntry found with Status of UNKNOWN"
      end
      alert_hash[jle.job_code][:green] << jle if jle.status.eql?('GREEN')
      alert_hash[jle.job_code][:red] << jle if jle.status.eql?('RED')
    #iterate over green's and subtract against red's
    end
    alert_hash.each_key do |job_code|
      alert_hash[job_code][:green].each_index do |index|
        green_jle = alert_hash[job_code][:green][index]
        red_jle = alert_hash[job_code][:red][index]
        #if the red_jle is nil we have an outage that spans the user selected dates.
        alert_time = green_jle.finish_time - red_jle.finish_time
        alert_hash[job_code][green_jle] = alert_time
      end
    end
    alert_pairs = []
    jles.each do |jle|
      next if jle.status.eql?('RED')
      pair = []
      pair << jle #put in the green
      red = alert_hash[jle.job_code][:red].shift
      pair << red
      alert_pairs << pair
    end
    return [alert_hash,alert_pairs.reverse!] if as_pairs
    [alert_hash,alert_pairs.reverse!.flatten]
  end

  def valid_alert_pairs_only(jles)
    jle_by_jc = {}
    jles_clone = jles.clone
    jles_clone.each do |jle|
      if (jle.status.nil?)
      jles_clone.delete(jle) #this job is still running
      next
      end
      jle_by_jc[jle.job_code] = [] if jle_by_jc[jle.job_code].nil?
      jle_by_jc[jle.job_code] << jle
    end
    jle_by_jc.each_key do  |jc|
      jles = jle_by_jc[jc]
      if (jles.first.status.eql?('RED'))
      remove_me = jles.shift
      jles_clone.delete(remove_me)
      end
      if ((jles.length > 0) && jles.last.status.eql?('GREEN'))
      remove_me = jles.pop
      jles_clone.delete(remove_me)
      end
    end
    jles_clone
  end

  def escalation_changes_only(jles_array)
    #jles is ordered newest to oldest
    jles =jles_array[1]
    return [[],[]] if jles.nil?
    status_jles = jles_array[0]
    ids = jles.map {|jle| jle.id}
    escalation_changes = []
    jles_clone = jles.clone
    alert_array = calculate_and_order_alert_times(status_jles, true)
    alert_times = alert_array[0]
    status_pairs = alert_array[1] #pairs is ordered newest to oldest
    status_pairs.each do |pair|
      escalations = []
      green = pair[0]
      #aaa_g_id = green.id
      red = pair[1]
      escalations << red
      prev_escalation = red.get_escalation
      #aaa_r_id = red.id 
      between_red_green = jles.reject {|jle| (red.id >= jle.id) or (green.id <= jle.id) or !green.job_code.eql?(jle.job_code) or jle.status.eql?("UNKNOWN")}
      #between_ids = between_red_green.map {|jle| jle.id}
      between_red_green.reverse.each do |some_jle|
        current_escalation = some_jle.get_escalation
        escalations << some_jle if (! current_escalation.eql?(prev_escalation))
        prev_escalation = current_escalation
      end
      escalations << green
      escalation_changes << escalations.reverse
    end
    return [alert_times, escalation_changes.flatten]
  end

end
