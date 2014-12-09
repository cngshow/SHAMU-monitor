require 'time_utils'

class ServiceController < ApplicationController

  def list
    job_engine = JobEngine.instance
    @services  = job_engine.get_services
    @page_hdr  = "Services Listing"

    unless (job_engine.started?)
      flash.now[:error] = "The Job Engine is not Running. No services can be executed."
    end

    respond_to do |format|
      format.html #list.html.erb
      format.xml { render :xml => @services }
    end
  end

  def show
    @service         = JobMetadata.find(params[:id])

    job_engine = JobEngine.instance
    @updateable_args = job_engine.gather_arguments(@service.job_code)
    init_nav_header

    if (! job_engine.started?)
      flash.now[:error] = "The job engine has not been started.  An administrator must start it before services can be requested."
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @service }
    end
  end

  def execute
    @service   = JobMetadata.find(params[:id])
    job_engine = JobEngine.instance
    if (job_engine.started?)
      #Need to change line 38 to submit a hash of value or nil if this service has no args
      flash[:notice] = job_engine.execute_service(@service, current_user)
    else
      flash[:error] = "The job engine is not active.  An administrator must start it first."
    end
    redirect_to :action => 'show', :id => @service.id
  end

  def execute_with_params
    @service   = JobMetadata.find(params[:id])
    job_engine = JobEngine.instance
    if (job_engine.started?)
      @sticky_value_hash = Hash.new
      @arg_error_hash    = Hash.new
      @updateable_args   = job_engine.gather_arguments(@service.job_code)
      arg_clone          = @updateable_args.clone
      val_change         = false

      @updateable_args.keys.each do |arg|
        arg_value               = params[arg]
        @sticky_value_hash[arg] = arg_value
        arg_validation_msg      = @updateable_args[arg][4]
        arg_regex               = @updateable_args[arg][5]

        unless (arg_value =~ /#{arg_regex}/)
          @arg_error_hash[arg] = arg_validation_msg
        else
          val_change     = val_change || !arg_value.eql?(job_engine.gather_cached_argument_val(@service.job_code, arg))
          arg_clone[arg] = arg_value
        end
      end

      if (@arg_error_hash.empty?)
        if (val_change)
          #Need to change line 38 to submit a hash of value or nil if this service has no args
          flash.now[:notice] = job_engine.execute_service(@service, current_user, arg_clone)
        else
          flash.now[:notice] = "No changes to the updateable arguments were made since the last run. Use the 'Execute Service' menu button above to get the job results." unless JobLogEntry.is_named_job_running?(@service.job_code)
          flash.now[:notice] = "Not Executing the service.  The system or another user has requested this job which is currently running." if JobLogEntry.is_named_job_running?(@service.job_code)
        end
      else
        flash.now[:error] = "The job engine is not running.  An administrator must start it first." if ! job_engine.started?
      end
      init_nav_header
      render :template => 'service/show'
    end
  end


  private

  def init_nav_header
    @page_hdr = "Execute Service:  " + @service.job_code
    @page_nav = [{ :label => 'Back to Services', :route => services_list_path }]
    @page_nav.push({ :label => 'Execute Service', :route => service_execute_path }) unless JobEngine.instance.stopped?
    @page_nav.push({ :label => 'Job Log Listing', :route => job_log_list_path })
  end

end
