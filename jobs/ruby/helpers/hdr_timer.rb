#!/u01/dev/ruby_1.8.7/bin/ruby

#this script is designed to keep the SHAMU HDR alert in sync with Michael Gabriel's updating of
#SHAMU_HDR_COUNTS.  Michael currently updates the table on the top of a ten minute period, so it would
#be updated at 12:00. 12:10, 12:20, 12:30 etc.  This script, based on the current time, will determine
#the last data set that should be populated, thus if the script is run at 12:03 it should return 
#11:50 to 12:00 format is yyyymmddhhmm or 201101111550 for 3:50 PM 2011 on January 11th.

now = Time.now
modded_min = now.min % 10
end_time = now - (modded_min)*60 - now.sec
begin_time = end_time - ARGV[0].to_i*60 

#puts end_time.to_s
#puts begin_time.to_s

begin_year = begin_time.year.to_s
begin_month = begin_time.strftime('%m') 
begin_day = begin_time.strftime('%d') 
begin_hour = begin_time.strftime('%H') 
begin_min = begin_time.strftime('%M')

end_year = end_time.year.to_s
end_month = end_time.strftime('%m') 
end_day = end_time.strftime('%d') 
end_hour = end_time.strftime('%H') 
end_min = end_time.strftime('%M')

print begin_year + begin_month + begin_day + begin_hour + begin_min + " " + end_year + end_month + end_day + end_hour + end_min
#sleep till the top of the fifth minute (5:15 PM, 5:25 PM, 5:35 PM  etc) assuming ARGV[1] is 5.
#This sleeping ensure's that Michael Gabriels's automation of the HDR data into our SHAMU table has had time to complete.

sleep_parameter = ARGV[1].to_i unless ARGV[1].nil?
sleep_parameter = 5 if (ARGV[1].nil? or (sleep_parameter>5))

if (modded_min < sleep_parameter)  
  sleep((60 - now.sec) + ((sleep_parameter - 1) - modded_min)*60)
  #puts "hdr_timer slept for #{slept} starting at time " << now.to_s
end