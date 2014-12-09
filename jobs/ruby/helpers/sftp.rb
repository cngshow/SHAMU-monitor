#sample invocation below:
#java -jar .\lib\jars\jruby-complete-1.6.7.2.jar .\jobs\utilities\monthlyADC\Jsftp.rb 67.208.88.234 doduser @complete55 C:\temp\foo.txt / 60 60

require 'java'
require '../../../jobs/jars/zehon_file_transfer-1.1.6.jar'
require '../../../jobs/jars/commons-logging-1.0.4.jar'
require '../../../jobs/jars/commons-vfs-2.0.jar'
require '../../../jobs/jars/jsch-0.1.41.jar'

java_import 'java.lang.System' do |pkg,cls|
  'JSystem'
  end

java_import 'java.io.ByteArrayOutputStream' do |pkg,cls|
  'JBAOut'
  end

java_import 'java.io.PrintStream' do |pkg,cls|
  'JPrintStream'
end

JSystem.setOut(JPrintStream.new(JBAOut.new))#This shuts the Zehon software up, or any chatty annoying jar for that matter...
JSystem.setErr(JPrintStream.new(JBAOut.new))#This shuts the Zehon software up, or any chatty annoying jar for that matter...

java_import 'com.zehon.sftp.SFTP' do |pkg, cls|
  'JSFTP'
end


SUCCESS = 1


def upload_monthly
    time = Time.now.strftime("%b-%d-%Y")
    file_end = $file.split($separator)[-1]
    new_file = "#{time}_#{file_end}"
    status = nil
   # raise "failed"
    status = JSFTP.sendFile($file,$sftp_dir,new_file ,$ip, $user, $password);

    raise "failure" if (status != SUCCESS)
    puts "Uploaded the file #{$file} as #{new_file} to #{$ip}"
end

$ip = ARGV[0] #50.201.159.229
$user = ARGV[1]#doduser
$password = ARGV[2]#@CompleteSS
$file = ARGV[3]#va-chdr-monthly-adc.zip
$sftp_dir = ARGV[4]#"/"
$separator = JSystem.getProperty("file.separator")
max_trys =  ARGV[5].to_i
sleep_between_trys =  ARGV[6].to_i
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