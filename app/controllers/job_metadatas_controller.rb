require 'time_utils'
require "job_engine"

class JobMetadatasController < ApplicationController
  skip_before_filter :login_required, :only => [ :trackables ]

  # GET /job_metadatas
  # GET /job_metadatas.xml
  def list
    admin_check
    @page_hdr = "Job Definition Listing"
    @job_metadatas = JobEngine.instance.get_job_meta_datas
    @time_zone_string = TimeUtils.offset_to_zone(session[:tzOffset])
    @offset = session[:tzOffset]
    respond_to do |format|
      format.html #list.html.erb
      format.xml  { render :xml => @job_metadatas }
    end
  end
  
  def trackables
    @page_hdr = "Trackable Jobs Listing"
    session[:trackables_refresh] = false if session[:trackables_refresh].nil?

    if (current_user)
      @page_nav = [{:label => "Auto Refresh: #{(session[:trackables_refresh] ? 'On' : 'Off')}",:route => trackables_refresh_path, :confirm => "Are you sure you want to turn auto-refresh #{(session[:trackables_refresh] ? 'Off' : 'On')}?"}]
    end
    
    @trackables = JobEngine.instance.get_trackable_jobs
    @status_jle = Array.new
    @trackables.each do |job_metadata|
      job_code = job_metadata.job_code
      jle = job_metadata.get_last_log_entry_with_status("Completed")
      @status_jle.push(jle) unless jle.nil?
    end
    respond_to do |format|
      format.html #trackables.html.erb     
#url will be http://0.0.0.0:3000/trackables?format=xml
      format.xml  { render :xml => @status_jle }
    end
  end

  def auto_refresh
    session[:trackables_refresh] = ! session[:trackables_refresh]
    redirect_to trackables_path
  end

  # GET /job_metadatas/1/edit
  def edit
    admin_check
    @job_metadata = JobMetadata.find(params[:id])
    edit_menu(@job_metadata)
    respond_to do |format|
      format.html { render :action => "edit" }
      format.xml  { render :xml => @job_metadata.errors, :status => :unprocessable_entity }
    end
  end
  
  # PUT /job_metadatas/1
  # PUT /job_metadatas/1.xml
  def update
    admin_check
    @job_metadata = JobMetadata.find(params[:id])
    edit_menu(@job_metadata)
    @offset = session[:tzOffset]
    time_error = false
    suspended = (params[:job_metadata][:suspend]).eql?("1")

    if suspended 
      stop_string = params[:job_metadata][:stop]
      resume_string = params[:job_metadata][:resume]
      offset = TimeUtils.offset_to_zone(session[:tzOffset])
      stop_string << ' ' << offset
      resume_string  << ' ' << offset
      params[:job_metadata][:stop] = stop_string
      params[:job_metadata][:resume] = resume_string
      resume = Time.parse(resume_string)
      stop = Time.parse(stop_string)
      error_strings = []
      messages =  OrderedHash.new()

      if (resume < stop)
        error_strings << 'The resume time must be later than the stop time.'
        messages["Update failed!"] = error_strings
        flash[:error] = render_to_string( :partial => "bulleted_flash", :locals => {:messages => messages})
        time_error = true
      end
      if (resume < Time.now)
        error_strings << 'The resume time must be later than the current time.'
        flash[:error] = render_to_string( :partial => "bulleted_flash", :locals => {:messages => messages})
        time_error = true
      end
    end
    
    respond_to do |format|
      if (@job_metadata.update_attributes(params[:job_metadata]) && !time_error)
        flash[:notice] = 'JobMetadata was successfully updated.'
        format.html { redirect_to(job_metadatas_list_path) }
        format.xml  { head :ok }
      else
        if time_error
          @job_metadata.suspend = false
          @job_metadata.save!
          @job_metadata.errors.add(:the, " suspension times are not valid. The job data was saved without the suspension data.")
        end

        messages = ["Update Failed!"]
        messages << errors_to_flash(@job_metadata.errors)

        flash.now[:error] = render_to_string(:partial => "bulleted_flash_single_header", :locals => {:messages => messages }) unless @job_metadata.errors.blank?
        format.html { render :action => "edit" }
        format.xml  { render :xml => @job_metadata.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  
  private
  def edit_menu(jmd)
      @page_hdr = "Edit Job Definition for:  " + jmd.job_code
      @page_nav = [{:label => 'Cancel', :route => job_metadatas_list_path},
                   {:label => 'Update', :route => job_metadatas_update_path}]
  end

end
