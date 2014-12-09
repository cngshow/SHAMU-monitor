require 'socket'
require 'stringio'

while true do
  begin
    sock = TCPSocket.new('localhost', 2001)
    t = Time.now.to_s
    #puts "Sending #{t}"
    sock.write("#{t}\n")
    sock.flush
    sock.close
    puts "Sent  #{t}"
    sleep 0.25
  rescue =>ex
    puts ex.to_s
  end

end
