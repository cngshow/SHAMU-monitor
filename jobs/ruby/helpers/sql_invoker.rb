require './jobs/ruby/lib/job'
require 'java'

java_import 'java.lang.System' do |pkg, cls|
  'JSystem'
end

#get the file separator
fs = JSystem.getProperties.getProperty("file.separator")
#puts fs + "<--------------------"
linux = JSystem.getProperties.getProperty("os.name").eql?('Linux')
require 'pty' if linux
#require 'expect' if linux

credentials = JobExecutor.get_credentials_http

#puts credentials[0] #user
#puts credentials[1] #password

sql_script = ARGV.shift
arguments = ARGV.join(" ")
sql_plus_string = 'sqlplus -s'
#sql_plus_string = 'sqlplus'

unless ENV['ORACLE_HOME'].nil?
  sql_plus_string =  "#{ENV['ORACLE_HOME']}"+ fs +"bin" + fs + sql_plus_string
end

connect_string = "CHDRP01.AAC.VA.GOV"

unless ENV['SHAMU_JOB_CONNECT'].nil?
  connect_string =  ENV['SHAMU_JOB_CONNECT']
end
result = nil
#execute sql script and store results
#PL/SQL procedure successfully completed.
if (linux)
    execute_cmd = "#{sql_plus_string} #{credentials[0]}@#{connect_string} @#{sql_script} #{arguments} 2>&1"
    PTY.spawn(execute_cmd) do |output,input, pid|
    input.printf("#{credentials[1]}\n")
    buffer = ""
    begin
      #loop { buffer << output.getc.chr; break if buffer =~ /PL\/SQL procedure successfully completed\.|ORA-\d{5}/}
      loop { value = output.getc; break if value.nil?; buffer << value.chr}
    rescue => ex
	buffer = ex.to_s
    end
    buffer.sub!("#{credentials[1]}","")
    buf_ar = buffer.split("\r\n")
    buf_ar.shift if buf_ar[0].eql?("")
    buf_ar.shift if buf_ar[0].eql?("")
    result = buf_ar.join("\r\n")
  end
else
  execute_cmd = "#{sql_plus_string} #{credentials[0]}/#{credentials[1]}@#{connect_string} @#{sql_script} #{arguments} 2>&1"
  result = `#{execute_cmd}`
end


#execute_cmd = "echo #{credentials[0]}/#{credentials[1]}@#{connect_string} @#{sql_script} #{arguments}; | #{sql_plus_string} "
#puts execute_cmd
#puts execute_cmd
execute_cmd_scrubbed = "#{sql_plus_string} #{credentials[0]}/#{credentials[0]}@#{connect_string} @#{sql_script} #{arguments}"
#puts execute_cmd_scrubbed



regex = Regexp.new(".*OUTPUT_BELOW:\n{0,1}(.*)OUTPUT_ABOVE:\n{0,1}.*", Regexp::MULTILINE)
if (result.match(regex))
#if (result =~ /.*OUTPUT_BELOW:(.*)OUTPUT_ABOVE:.*/m)  #this does not work in jruby with /s, /m or /ms.  What gives?
  result = $1
  print result
  exit 0
end

regex = Regexp.new(".*(EMAIL_RESULT_BELOW:.*EMAIL_RESULT_ABOVE:).*", Regexp::MULTILINE)
if (result.match(regex))
#if (result =~ /.*(EMAIL_RESULT_BELOW:.*EMAIL_RESULT_ABOVE:).*/s)
  result = $1
  print result
  exit 0
end

regex = Regexp.new(".*(<html>.*<\/html>).*", Regexp::MULTILINE)
if (result.match(regex))
#if (result =~ /.*(<html>.*<\/html>).*/s)
  result = $1
  print result
  exit 0
end

print result
#keep going
