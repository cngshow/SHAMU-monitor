def file_as_string(file)
  rVal = ''
  File.open(file, 'r') do |file_handle|
    file_handle.read.each_line do |line|
      rVal << line
    end
  end
  rVal
end

sig_sent = false
signal = ARGV[0]
signal = "SIGINT" if signal.nil?
pid = file_as_string("./log/pid.txt")
puts "sending #{signal} to #{pid}"
pid= pid.to_i
begin
  Process.kill("SIGINT", pid)
  sig_sent = true
rescue => ex
  puts ex.to_s
end

unless sig_sent
  me = ENV['USER']
  pid = "ps -ef | grep mongrel | grep #{me}"
  puts "Try running the following and manually killing:"
  puts pid
end