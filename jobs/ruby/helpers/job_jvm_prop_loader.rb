require 'java'
require './lib/prop_loader.rb'

module JobJVMPropLoader

  def load_jvm_properties(prop_file)
    raise "JVM property file #{prop_file} does not exist!" unless File.exist? prop_file
    sys_props = java.lang.System.getProperties
    new_props = PropLoader.load_properties(prop_file)
    new_props.each_pair do |key, value|
      $logger.debug("Adding #{key}=#{value} to the system properties.") unless $logger.nil?
      sys_props.put(key.strip,value.strip)
    end
  end

end