class RegistrationsController < Devise::RegistrationsController
  prepend_view_path "app/views/devise"

  def new
    @page_hdr = "Create a New User Account"
    #kill all the users before we save
    #User.destroy_all
    #cnt = User.count
    super
  end

  def create
    @page_hdr = "Create a User Registration Account"
    offset = params[:hidTz]
    session[:tzOffset] = offset

    # Generate your profile here
    # ...test
    super
  end

  def update
    @page_hdr = "User Registration Update"
    super
  end

  def edit
   @page_hdr = "User Registration Edit"
   @user_count = User.count
   @admin_count = User.count(:conditions => ["administrator = ?", true])
   super
  end
end
