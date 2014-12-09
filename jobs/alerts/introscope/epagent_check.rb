#!/u01/dev/ruby_1.8.7/bin/ruby

$agent_status = '__RED_LIGHT__'
$epagent_home = ARGV[0]

def get_agent_status
  command = `ps -ef | grep java | grep EPAgent.jar | grep #{ENV['USER']}`
  agent_status_query_response = command.split("\n")
  puts agent_status_query_response
  $agent_status = '__GREEN_LIGHT__' if agent_status_query_response.length >= 2
  puts $agent_status
end

def start_agent
  command = "cd #{$epagent_home} && java -jar #{$epagent_home}/lib/EPAgent.jar &"
  system(command)
end
  
#check current agent status
get_agent_status

#if in RED LIGHT status, try to start agent
if $agent_status.eql? '__RED_LIGHT__'
  #attempt to start agent
  command = `echo \'cd #{$epagent_home} && java -jar #{$epagent_home}/lib/EPAgent.jar &\' | at now`
  puts "Started EPAgent via #{command}"
end
