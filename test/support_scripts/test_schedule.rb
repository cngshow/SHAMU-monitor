#log cron results...
set :output, {:error=>'C:\Perforce\vhaislprf2_1666\vhaiswshuppc\chdr\current\Development\Utilities\ProductionSupportTools\SHAMU\PSTDashboard\pst_cron_error.log', :standard=>'C:\Perforce\vhaislprf2_1666\vhaiswshuppc\chdr\current\Development\Utilities\ProductionSupportTools\SHAMU\PSTDashboard\pst_cron_stdout.log'}

RAILS_ROOT = './'

#Rebooting not supported in quartz!
#every :reboot do
##Start MONGREL: 3010 is the listening port and 60 seconds is the amount of time to gives threads to complete
#  command "cd #{RAILS_ROOT} && ./startup"
#end

every 1.day, :at=>'3:00 am' do
   command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl MESSAGE_BREAKDOWN_CHARTS"
end

every 1.day, :at=>'7:15 am' do
   command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl MESSAGE_FLOW_RPT_DAILY"
end

every 1.day, :at=>'7:00 am' do
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl DUPLICATION_STATISTICS"
end

every 1.day, :at=>'6:15 am' do
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl NO_RESPONSE_CHECK_NIGHTLY"
end

every 1.day, :at=>'8:00 am' do
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl DOD_ADC_REQUEST_CHECK"
end

every 1.month, :at=>'start of the month at 8:05 am' do
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl MONTHLY_ADC"
end

every 1.month, :at=>'start of the month at 5:45 am' do
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl MESSAGE_FLOW_RPT_MONTHLY"
end

#Message traffic checks
#=begin
every 10.minutes do
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl DOD_BATCH_EXCHANGE_ALERT"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl DUPLICATION_CHECK"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl NO_DOD_TRAFFIC"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl NO_Z04_MESSAGES_RECEIVED"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl NO_Z03_VISTA_MESSAGES_SENT_TO_DOD"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl NO_TRAFFIC_ALERT"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl Z03_Z04_FREQ_TRAFFIC_CHECK"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl DOD_ADC_AUTOMATION_LOW_ALERT"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl DOD_ADC_AUTOMATION_HIGH_ALERT"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl DUPLICATION_ALERT"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl MPI_ALERT"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl TRAFFIC_FLOW_ALERT_DOD"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl TRAFFIC_FLOW_ALERT_VA"
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl VISTA_ALERT"
end
#=end

#checks status for introscope agent
#=begin
every 30.minutes do
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl EPAGENT_CHECK"
end
#=end

#schedule for known outages
=begin
every :friday, :at=>'3:57 pm' do
  command "cd #{RAILS_ROOT} && bash ./suspend"
end
every :friday, :at=>'3:59 pm' do
  command "cd #{RAILS_ROOT} && bash ./resume"
end
=end

#Run the weekly ADC report and message traffic flow on Monday mornings
every :monday, :at=>'7:57 am' do
   command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl MESSAGE_FLOW_RPT_WEEKLY"
end

#Run the ADC Analyzer report on Tuesday mornings
every :tuesday, :at=>'7:57 am' do
   command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl ADC_ANALYZER_CHARTS"
   command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl ADC_OVERLAY_CHARTS"
end

=begin
every 1.day, :at=>'3:20 pm' do
#Start MONGREL: 3010 is the listening port and 60 seconds is the amount of time to gives threads to complete
  command "cd #{RAILS_ROOT} && ./startup.pl 3008 60"
end
=end

#start the job every hour @ minute 05,15,25,35,45,55
every 1.day, :at => ('00'..'23').to_a.collect {|x| ["#{x}:05" , "#{x}:15" , "#{x}:25" , "#{x}:35", "#{x}:45" , "#{x}:55"]}.flatten do
  command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl HDR_ALERT"
end

every 1.day, :at=>'6:00 am' do
   command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl HIST_CHARTING"
end

every :monday, :at=>'6:05 am' do
   command "cd #{RAILS_ROOT} && ./jobs/perl/execute_job.pl Z03_SITE_ANALYSIS"
end

every 1.minutes do
  command "cd #{RAILS_ROOT} && echo hi"
end
