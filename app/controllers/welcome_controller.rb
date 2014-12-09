class WelcomeController < ApplicationController
  #skip_before_filter :login_required

  def index
    @page_hdr = "Welcome to SHAMU - the System Health Alert Monitoring Utility"
    @admin_count = User.count(:conditions => ["administrator = ?", true])
    @user_count =  User.count(:all)

    #ensure that the first user that is logged in is set as an administrator
    if (current_user && @user_count == 1 && !current_user.administrator)
      current_user.administrator = true
      current_user.save
      @admin_count = 1
    end
  end
end
