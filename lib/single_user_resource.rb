require 'monitor'

class SingleUserResource
  
  def check_out!(user)
    @@lock.synchronize {
      return false if checked_out? && ! checked_out_by?(user)
      @current_user = user
      return true
    }   
  end
  
  def check_in!(user)
    @@lock.synchronize {
      return unless is_me?(user)
      @current_user=nil
    } 
  end
  
  def is_available?(user)
    @@lock.synchronize {
      return !checked_out? || is_me?(user)
    } 
  end
  
  def get_current_user()
    @@lock.synchronize {
      @current_user
    }
  end
  
  def self.update_activity_time!(user, time)
    @@lock.synchronize {
      @@activity_hash[user.email] = time
    }
  end
  
  def self.user_logged_out!(user)
    @@lock.synchronize {
      @@activity_hash[user.email] = Time.now
    }
  end
  
  def initialize

  end
  
  protected
  @@lock = Monitor.new
  @@activity_hash = {}
  
  def checked_out_by?(user)
    @@lock.synchronize {
      return checked_out? && is_me?(user)
    }
  end
  
  def checked_out?
    @@lock.synchronize {
      return false if @current_user.nil?
      last_usage = @@activity_hash[@current_user.email]
      elapsed = last_usage - Time.now
      expired = last_usage - Time.now <= 0
      if expired
        clean_up_resource
        @current_user = nil
        return false
      end
      return true
    }
  end
  
  private
  
  @current_user = nil;

  def is_me?(user)
    @current_user.email.eql?(user.email)
  end
  
end