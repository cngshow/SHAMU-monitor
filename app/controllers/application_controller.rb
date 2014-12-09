# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'PST_logger'
require 'single_user_resource'
require 'job_data'
require 'monitor'
require 'thread_pool'
require 'prop_loader'
require 'orderedhash'
require './lib/sendmail'
require 'job_engine'

class ApplicationController < ActionController::Base
  protect_from_forgery # See ActionController::RequestForgeryProtection for details IE 6.0 cannot handle this, when going from a page requiring a login to one that does not
  helper :all # include all helpers, all the time
  include ApplicationHelper
  before_filter :update_activity_time, :job_engine_status

  @job_engine_status = nil
  @@request_pool = ThreadPool.new(10)

  def admin_check
    raise "Insufficient privileges" if !admin_check?
  end
  
  def update_activity_time
    session[:expires_at] = $application_properties['inactivity_time_out'].to_i.minutes.from_now
    unless current_user.nil?
      SingleUserResource.update_activity_time!(current_user, session[:expires_at])
      current_user.last_activity_datetime = Time.now
      current_user.save
    end
  end

=begin
  def initialize
    @user_count = User.count
    @admin_count = User.count(:conditions => ["administrator = ?", true])
    super
  end
=end

protected
  def only_beta
    beta_users = $application_properties['beta_users'].split(',')
    beta_controllers = $application_properties['beta_controllers'].split(',')
    current_controller = self.class.to_s

    if ((beta_controllers.grep(current_controller).length) > 0)
      raise "Only approved beta users have access." if (beta_users.grep(current_user.login).length) == 0
    end
  end

private
  def job_engine_status
    color = "red"
    status = "unknown"
    $logger.debug("calling job_engine_status instance")

    if (JobEngine.instance.started?)
      color = "green"
      status = "Running"
    elsif (JobEngine.instance.stopping?)
      status = "Stopping"
    elsif (JobEngine.instance.stopped?)
      status = "Not Running"
    end

    @job_engine_status = [color,status]
  end
end
