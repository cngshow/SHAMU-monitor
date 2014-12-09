#sample invocation below:
#java -jar .\lib\jars\jruby-complete-1.6.7.2.jar .\jobs\utilities\monthlyADC\Jsftp.rb 67.208.88.234 doduser @complete55 C:\temp\foo.txt / 60 60

require 'java'
LIB_PATH = ARGV[8] + '/'
Dir.entries(LIB_PATH).each do |file|
  require "#{LIB_PATH}#{file}" if file =~ /jar$/
end

java_import 'net.sf.opensftp.SftpUtilFactory' do |pkg, cls|
  'JSftpUtilFactory'
end

java_import 'net.sf.opensftp.SftpSession' do |pkg, cls|
  'JSftpSession'
end

java_import 'net.sf.opensftp.SftpUtil' do |pkg, cls|
  'JSftpUtil'
end

java_import 'java.lang.System' do |pkg,cls|
  'JSystem'
end

#JSystem.getProperties.setProperty("log4j.debug","")

SUCCESS = true


def upload_monthly
    time = Time.now.strftime("%b-%d-%Y")
    file_end = $file.split($separator)[-1]
    new_file = "#{time}_#{file_end}"
    status = false
    util = JSftpUtilFactory.getSftpUtil
    session = util.connectByPasswdAuth($ip, $user, $password,JSftpUtil.STRICT_HOST_KEY_CHECKING_OPTION_NO)
    return if (session.nil?)
    result = util.cd(session, $sftp_dir)
    puts "Changed directories to #{$sftp_dir}" if result.getSuccessFlag
    puts "directory change to  #{$sftp_dir} failed! -- " + result.getErrorMessage unless result.getSuccessFlag
    result = util.put(session, $file, new_file); #upload a file and rename the copy
    puts result.getErrorMessage unless result.getSuccessFlag
    status = result.getSuccessFlag
    util.disconnect(session)
   # raise "failed"
   #status = JSFTP.sendFile($file,$sftp_dir,new_file ,$ip, $user, $password)

    raise "failure" if (status != SUCCESS)
    puts "Uploaded the file #{$file} as #{new_file} to #{$ip}"
end

$ip = ARGV[0] #50.201.159.229
$user = ARGV[1]#doduser
$password = ARGV[2]#@CompleteSS
#puts "The password is #{$password}"
$file = ARGV[3]#va-chdr-monthly-adc.zip
$sftp_dir = ARGV[4]#"/"
$separator = JSystem.getProperty("file.separator")
max_trys =  ARGV[5].to_i
sleep_between_trys =  ARGV[6].to_i
log4j_config = ARGV[7]

puts "************************************" + log4j_config

JSystem.getProperties.setProperty("log4j.configuration","file:#{log4j_config}")

success = false
current_try = 0

until (success or (max_trys < current_try))
  begin
    current_try = current_try + 1
    puts "Starting upload..."
    upload_monthly
    puts "Upload complete!"
    success = true
  rescue => ex
    puts ex.class.to_s
    puts ex.to_s
    puts "Current attempt is #{current_try}"
    sleep(sleep_between_trys)
  end
end
puts "Upload failed!" unless success
puts "Upload was successful" if success
#jruby open_sftp.rb 50.201.159.229 doduser DevImage99! small  / 0 60
