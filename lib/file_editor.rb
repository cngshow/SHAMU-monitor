require 'ftools'
require 'single_user_resource'
require 'monitor'

class FileEditor < SingleUserResource
  def get_file
    @file_lock.synchronize {
      begin
        open(@file_name) do |f|
          return f.read        
        end
      rescue =>ex
        $logger.error("I could not open #{@file_name} .  The error is " << ex.to_s)
        raise ex
      end
    }
  end
  
  #the validation_proc must return an array of at least size two.
  #the first spot is a boolean indicating success or failure, the second is a result string for display to the user
  def write_file(user,file,validation_proc)
    @file_lock.synchronize {
      raise 'You do not have this file checked out' unless checked_out_by?(user)
      File.send(:move, @file_name, @file_name_bak) if @valid_file.call
      
      begin
        open(@file_name,'w') do |f|
          f.puts file
          f.flush         
        end
      rescue => ex
        $logger.error("I could not open #{@file_name} for writing .  The error is " << ex.to_s)
        raise ex
      end
      validation_proc.call
    }
  end
  
  def revert(user)
    @file_lock.synchronize {
      can_revert = revertable.call
      return can_revert unless can_revert
      successful_reversion = true
      raise 'You do not have this file checked out' unless checked_out_by?(user) 
      begin
        File.send(:move, @file_name_bak, @file_name) unless @valid_file.call
      rescue =>ex
        $logger.error "Reversion of #{@file_name_bak} to #{@file_name} failed " << ex.to_s
        successful_reversion = false
      end  
      successful_reversion
    }
  end
  
=begin
  def rollback(user)
    @file_lock.synchronize {
      raise 'You do not have this file checked out' unless checked_out_by?(user)
      File.send(:move, @file_name_bak, @file_name)
      #call whenever
    }
  end
=end
  
  def self.instance(filename) 
    @@lock.synchronize {
      instance = @@instances[filename]
      if (instance.nil?)
        instance = FileEditor.new(filename)
        @@instances[filename] = instance
      end
      instance
    }
  end
  attr_accessor :revertable, :valid_file
  
  protected
  
  
  def clean_up_resource
    @file_lock.synchronize {
      File.send(:move, @file_name_bak, @file_name) if (!@valid_file.call and @revertable.call)
    }
  end
  
  private
  
  @@instances = Hash.new
  #  @@schedule_file = $application_properties['ruby_cron'] 
  #  @@schedule_file_bak = $application_properties['ruby_cron_bak'] 
  def initialize(file_name)
    @file_name = file_name
    @file_name_bak = @file_name + '.bak'
    @file_lock = Monitor.new
  end
  
  def to_backup(filename, move=false)
    new_filename = nil
    if File.exists? filename
      new_filename = File.versioned_filename(filename)
      File.send(move ? :move : :copy, filename, new_filename)
    end
    return new_filename
  end
  
  def versioned_filename(base, first_suffix='.0')
    suffix = nil
    filename = base
    while File.exists?(filename)
      suffix = (suffix ? suffix.succ : first_suffix)
      filename = base + suffix
    end
    return filename
  end
  
end
