require './lib/prop_loader'
require 'socket'
require 'stringio'
require 'open-uri'


class JobExecutor

  def JobExecutor.get_credentials_http
    port = 3000 #assume development ()if launched from IDE rails_port.txt might not exist
    begin
      port = JobExecutor.file_as_string('./log/rails_port.txt').chomp.strip
    rescue

    end
    url = "http://127.0.0.1:#{port}/key_value_fetch?request=credentials"
    contents = URI.parse(url).read
    creds_array = contents.split('|')
    creds_array
  end

  def JobExecutor.get_credentials
    creds_array = []
    sock = JobExecutor.get_socket
    sock.write("__credentials\n")
    sock.flush
    results = StringIO.new(sock.read)
    results.each_line do 
      |line|
      line.chomp!
      creds_array = line.split(',')
    end
    sock.close
    creds_array
  end

  def self.are_credentials_valid?
    begin
      sock = JobExecutor.get_socket
      sock.write("__are_credentials_valid\n")
      sock.flush
      results = StringIO.new(sock.read)
      result = nil
      results.each_line do
        |line|
        line.chomp!
        result = line
      end
      sock.close
      return result.eql?("true")
    end
  end

  def JobExecutor.execute_job(job)
    begin
      sock = JobExecutor.get_socket
      job.chomp!

      sock.write(job + "\n")
      sock.flush
      sock.close
    rescue => ex
      $stderr.puts(ex.to_s)
      return false
    end
    return true
  end
 
private
    
  def JobExecutor.get_job_engine_port
    @properties = PropLoader.load_properties('./pst_dashboard.properties') if @properties.nil?
    @properties['job_engine_port'].to_i
  end
  
  def JobExecutor.get_socket
    TCPSocket.new('localhost', JobExecutor.get_job_engine_port)
  end

  def JobExecutor.file_as_string(file)
			rVal = ''
			File.open(file, 'r') do |file_handle|
				file_handle.read.each_line do |line|
					rVal << line
				end
			end
			rVal
		end

  @properties = nil
end

#a = JobExecutor.get_credentials
#puts a[1]
