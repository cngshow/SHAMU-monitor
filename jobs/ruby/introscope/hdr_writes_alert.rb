require './jobs/ruby/introscope/metrics_data_service'
require 'time'

end_point = ARGV[0]   #"http://apmmom1prd.aac.va.gov:8082/introscope-web-services/services/MetricsDataService"
user = ARGV[1]        #"hdr2apm"
password = ARGV[2]    #"shamu9812!"
agent_regex = "(.*)EPAgentProc-HDR\\|EPAgent-HDR(.*)"
metric_regex = ".*HDR2_WRITES.*CHDR.*HDRALGY.*Message.*Count" #will get two buckets add them for total writes
#"(.*)CHDR:Message Count" If we use this regex expect 2 get two metric buckets not one.  The first is reads, the second is writes.
#.*HDR2_READS.*CHDR.*LAB.*Message.*Count if we use this one it is exclusively read messages (one bucket)

lookback = ARGV[3]
now = Time.now
modded_min = now.min % 10
end_time = now - (modded_min)*60 - now.sec
start_time = end_time - lookback.to_i*60
failure = false
data_frequency = 600
mds = MetricsDataService.new(end_point, user, password)
metrics = []
begin
  #raise "For testing!" COMMENT OUT IN PRODUCTION!
  metrics = mds.get_metric_data(agent_regex, metric_regex, start_time, end_time, data_frequency)
rescue => e
 $stderr.puts e.to_s
end

failure = (metrics.size == 0)
value = 0
metrics.each do |metric|
  start_time = metric[0]
  end_time = metric[1]
  values = metric[2]
  value = values[0].to_i +  values[1].to_i
  #puts "Between time #{start_time} and #{end_time} there were #{value} hdr writes"
end
#value = 0 #for testing red condition.  COMMENT OUT IN PRODUCTION!
result = start_time.strftime('%Y%m%d%H%M') + " " + end_time.strftime('%Y%m%d%H%M')
result = result + " FAILURE #{value}" if failure
result = result + " SUCCESS #{value}" unless failure
print result