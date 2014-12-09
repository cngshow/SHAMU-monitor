class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :encryptable, :authentication_keys => [:login]

  # Setup accessible (or protected) attributes for your model #:username added by cris and greg
  attr_accessible :email, :password, :password_confirmation, :remember_me, :username, :last_activity_datetime
  attr_accessible :login

  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  #attr_accessible :username, :email, :password, :password_confirmation, :remember_me

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  alias_attribute :login, :username

  def self.mark_all_as_admin
    User.update_all(:administrator => true)
    #@users = User.find(:all)
    #@users.each do  |user|
    #  user.administrator=true
    #  user.save
    #end
  end

  def password_salt
    'no salt'
  end

  def password_salt=(new_salt)
  end

end
