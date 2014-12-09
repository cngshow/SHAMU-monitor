class SystemProp < ActiveRecord::Base
  
  def self.set_prop(key, value)
    #puts("Attempting to set #{key} to #{value} ")
    sp = SystemProp.find_prop(key)
    if (sp.nil?)
      sp = SystemProp.new
      sp.key = key
    end
    
    sp.value = value
    save = sp.save(:validate => false)
    #puts("set_prop completed! Saved = #{save}")
  end
  
  def self.get_value(key)
    prop = SystemProp.find_prop(key)
    #puts prop.value unless prop.nil?
    #puts "No value found for key #{key}" if prop.nil?
    return nil if prop.nil?
    prop.value
  end
  
  def self.destroy_props()
    SystemProp.delete_all('1=1')
  end  

  private
  
  def self.find_prop(key)
    SystemProp.find(:all, :conditions => ["key = ?", key])[0]
  end
end
