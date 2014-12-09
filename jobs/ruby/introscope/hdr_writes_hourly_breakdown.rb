
require './jobs/ruby/introscope/metrics_data_service'
require 'time'

end_point = ARGV[0] #"http://apmmom1prd.aac.va.gov:8082/introscope-web-services/services/MetricsDataService"
user = ARGV[1] #"hdr2apm"
password = ARGV[2] #"shamu9812!"
agent_regex = "(.*)EPAgentProc-HDR\\|EPAgent-HDR(.*)"
metric_regex = ".*HDR2_WRITES.*CHDR.*HDRALGY.*Message.*Count" #will get two buckets add them for total writes
#"(.*)CHDR:Message Count" If we use this regex expect 2 get two metric buckets not one.  The first is reads, the second is writes.
#.*HDR2_READS.*CHDR.*LAB.*Message.*Count if we use this one it is exclusively read messages (one bucket)

date = ARGV[3]
date_offset_in_days = ARGV[4]
raise "day offsets < 1 are not supported!" if (date_offset_in_days.to_i < 1)
raise "Incorrect date format! -- #{date}" unless date =~ /(\d{4})(\d\d)(\d\d)/
end_date = Time.local($1, $2, $3)
start_date = end_date - date_offset_in_days.to_i*24*60*60
failure = false
data_frequency = 60*60
failure_error_string = ''
mds = MetricsDataService.new(end_point, user, password)
metrics = []
begin
  #raise "For testing!" #COMMENT OUT IN PRODUCTION!
  metrics = mds.get_metric_data(agent_regex, metric_regex, start_date, end_date, data_frequency)
rescue => e
  failure_error_string = e.to_s
end

before_html = <<BEFORE_HTML

<h4>VA CHDR Hourly Messages Written to HDR<br>Activity for THE_DATE</h4>
<div class="section">Hourly Breakdown of Messages (Reported in Central Time)</div>
<div class="rpt_display">

<table class="display" cellspacing=0>
<tr><th width="16%"><br>Date/Hour</th>
<th width="14%">Messages<br>Written</th>
<th width="70%"></th>
</tr>
BEFORE_HTML

data_html = <<DATA_HTML
  <tr class="ODD_EVEN">
  <td>TIME</td>
  <td>COUNT</td>
  <td>FAILURE</t
  </tr>
DATA_HTML

end_html = <<END_HTML
<tr class="totals">
<td>Totals</td>
<td>TOTAL_HDR_WRITES</td>
<td>&nbsp;</td>
</tr>
</table>
<br>
</div>
<br></div><br><br>
END_HTML


start_time_string = start_date.strftime('%B %d, %Y')
before_html.gsub!('THE_DATE', start_time_string)
puts before_html
failure = (metrics.size == 0)
value = 0
total = 0
count = 0
unless failure
  metrics.each do |metric|
    start_time = metric[0]
    end_time = metric[1]
    values = metric[2]
    puts "Invalid frequency, please tell a SHAMU administrator you saw this message!!!!" if (values.size > 2) #we currently expect exactly two metrics from this regex(metric_regex)
    value = values[0].to_i +  values[1].to_i
    start_time_string = start_time.strftime('%b').upcase + start_time.strftime('-%d %H')
    total = total + value.to_i
    row_style = (count%2 == 0) ? 'even' : 'odd'
    puts data_html.gsub('TIME', "#{start_time_string}").gsub('FAILURE','&nbsp;').gsub('COUNT', value.to_s).gsub('ODD_EVEN',row_style)
    #puts "Between time #{start_time_string} and #{end_time_string} there were #{value} hdr writes"
    count = count + 1
  end
else
  puts data_html.gsub('TIME',"&nbsp;").gsub('COUNT','&nbsp;').gsub('FAILURE',"Could not get the data from Introscope -- #{failure_error_string}")
end

#value = 0 #for testing red condition.  COMMENT OUT IN PRODUCTION!
end_html.gsub!('TOTAL_HDR_WRITES', total.to_s) unless failure
end_html.gsub!('TOTAL_HDR_WRITES', 'unknown') if failure
puts end_html