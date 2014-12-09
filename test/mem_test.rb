require 'gserver'
require 'monitor'


class JobEngine2 < GServer

  attr_accessor :T


  def initialize(port=2001, host=GServer::DEFAULT_HOST)
    super(port, host, 1, nil, true, true)
    @T = Time.now
    start
  end

  def serve(sock)
    request = sock.readline
    request.chomp!
    puts "got request #{request}, executing something"

    my_lambda = lambda do
      result = ''
      #result = `jruby -e 'puts  Time.now.to_s'`
      system("jruby -e 'puts  Time.now.to_s'")
      puts "#{@T} -- #{request} ---> #{result}"
    end
    #@job_pool.dispatch(my_lambda,"some tag",request,"JLE string")
    my_lambda.call
  end

end

#je = JobEngine2.new
#puts "Starting at #{je.T}..."
puts "My pid #{$$}"
while (true) do
 # sleep 1
  #puts `pwd`
  #puts `c:\\Java\\jdk1.6.0_30\\bin\\java -jar ../lib/jars/jruby-complete-1.6.7.2.jar -e "puts  Time.now.to_s"` #OK
  puts `c:\\Java\\jdk1.6.0_30\\bin\\java -jar ../lib/jars/jruby-complete-1.6.7.2.jar time.rb` #OK
  #puts `jruby -e 'puts  Time.now.to_s'` #bombs out of memory
  #puts `jruby time.rb` #bombs out of memory
  #puts `echo %time%` #OK
end
