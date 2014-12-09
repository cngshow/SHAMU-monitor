
module ShamuExternal
  def self.get_lambda
    $logger.debug("Running template builder")
    lambda do |arguments|
      prop_file = arguments.shift
      write_file = arguments.shift
      subs = arguments.shift
      audit_user = JobData.oracle_id
      audit_password = JobData.oracle_password
      props = Utilities::FileHelper.file_as_string(prop_file)
      subs.split(/\|/).each do |param|
        $logger.info("PARAM="+param)
        if (param =~ /(.*?)=(.*)/)
          sub = $1.strip
          val = $2.strip
          $logger.debug("sub="+sub)
          $logger.debug("val="+val)
          val = audit_user if (val.eql?("AUDIT_USERNAME"))
          val = audit_password if (val.eql?("AUDIT_PASSWORD"))
          props.gsub!(sub){|m| val}
        end
      end
      File.open(write_file, "wb") do |file| file.write(props) end
      $logger.debug("Done w/ template builder")
      return ""#return an empty string when not doing anything...
    end
  end
end
ShamuExternal.get_lambda
