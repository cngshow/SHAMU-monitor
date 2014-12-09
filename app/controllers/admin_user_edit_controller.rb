class AdminUserEditController < ApplicationController

  def update
    admin_check
    begin
      #raise "This is my error!!!!!!"  #for testing
      users = User.find :all
      failed_deletes = []
      failed_updates = []
      users.each do |user|
        next if user.eql?(current_user)
        id = user.id
        delete_cbx = !params["delete_check_box-#{id}"].nil?
        admin_cbx = !params["admin_check_box-#{id}"].nil?
        if (delete_cbx)
          user.destroy
          failed_deletes << user.email unless user.destroyed?
        else
          user.administrator = admin_cbx
          updated = user.save
          #updated = false
          failed_updates << user.email unless updated
          #failed_updates << user.email #failure testing@
          #failed_deletes << user.email #failure testing@
        end
      end

      if (failed_deletes.empty? and failed_updates.empty?)
        flash[:notice] = 'Update succeeded!'
      else
        #failed_deletes.unshift "Deletes failed!"
        #failed_updates.unshift "Update failed!"
        messages =  OrderedHash.new()
        messages["Deletes failed!"] = failed_deletes unless failed_deletes.empty?
        messages["Update failed!"] = failed_updates unless failed_updates.empty?
        #messages = [failed_deletes, failed_updates]
        flash[:error] = render_to_string( :partial => "bulleted_flash", :locals => {:messages => messages})
      end
    rescue Exception => e
      #messages = ["Update failed!", e.to_s]
      messages =  OrderedHash.new()
      messages["Update failed!"] = e.to_s #or optionally [e.to_s]
      flash[:error] = render_to_string( :partial => "bulleted_flash", :locals => {:messages => messages})
    end
    redirect_to (admin_user_list_path(current_user))
  end

  def list
    admin_check
    @user_list = User.all
    @page_hdr = "Listing of Users"
    @page_nav = [{:label => 'Cancel', :route => root_path},
                 {:label => 'Update', :submit_form_name => 'admin_user_update'}]
    #the :submit_form_name tag (used above) will in most cases point to '0' as there will be only one form element
  end

  private

end
