require 'job_engine'
require 'job_data'

class JobController < ApplicationController
   #ssl_required :credentials

  #setup before displaying credentials.html.erb
  def credentials
    admin_check
    @page_hdr = "Please Enter the Job Credentials " + current_user.login
  end
  
  def stop_engine
    start_engine(false)
  end
  
  def start_engine(start_it = true)
    user_data = params[:user]

    if (!user_data.nil?)
      id_change = JobData.oracle_id != user_data[:oracle_id]
      connected = JobData.connect_to_oracle(user_data[:oracle_id], user_data[:oracle_password])

      if (!connected[0])
        error = "The ID "+user_data[:oracle_id]+" could not be used.<br>"
        error << "The message from the database is:<br>"
        error << connected[1]
        flash[:error] = error
        redirect_to setcredentials_path
        return# do I need this?  Check debugger one day
      end

      if (id_change)
        #put in a check to ensure this ID can reach Oracle before stopping the current engine
        JobEngine.instance().stop!
        $logger.info('The user ' << current_user.login << ' has stopped the job engine.')
      end
      $logger.info('The user ' << current_user.login << ' has started the job engine.')
      JobEngine.instance().start!
    else
      #we are coming from the start_engine.html.erb page
      #we will toggle the state (switch from on to off or off to on
      
      #  JobEngine.instance.toggle!(RAILS_DEFAULT_LOGGER)
      if start_it
          connected = JobData.connect_to_oracle_with_current_ID
          if (!connected[0])
            error = "The ID "+JobData.oracle_id+" could not be used.<br>"
            error << "The message from the database is:<br>"
            error << connected[1]
            flash[:error] = error
            return # do not start
          end
          JobEngine.instance().start! 
      else
        JobEngine.instance().stop! 
      end
    end
    
    redirect_to job_metadatas_list_path
    return# do I need this?  Check debugger one day
  end
end
