VHA       = "VHACHDR.MED.VA.GOV"
DOD       = "DODCHDR.HA.OSD.GOV"

#the SQL to run checking the Z03 failure counts for a given time period
sql = %{
select nvl(sum(a.outcome), 0) as success_count,
       nvl(sum(case a.outcome when 1 then 0 else 1 end),0) as failure_count,
       count(*) as total
from  chdr2.audited_event a
where a.sending_site = 'Z03_SENDING_SITE'
and   a.receiving_site = 'Z03_RECEIVING_SITE'
and   a.EVENT_TYPE in ('FILL','PRES','ALGY')
--and   a.CREATED_DATE between to_date('20131206001200','yyyymmddhh24miss') and to_date('20131206032200','yyyymmddhh24miss')
and   a.CREATED_DATE between to_date('START_DATE','yyyymmddhh24miss') and to_date('END_DATE','yyyymmddhh24miss')
}

job_code = ARGV.shift
lookback = ARGV.shift.to_i
min_z03_required = ARGV.shift.to_i
last_known_status = ARGV.shift
alert_pct = ARGV.shift.to_i
clearing_pct = ARGV.shift.to_i

end_date = Time.now
start_date = Time.at(end_date - (lookback*60))

#set up the SQL to retrieve replay messages
sql.gsub!("START_DATE") { |match| start_date.strftime("%Y%m%d%H%M%S") }
sql.gsub!("END_DATE") { |match| end_date.strftime("%Y%m%d%H%M%S") }
sql.gsub!("Z03_RECEIVING_SITE") { |match| VHA }
sql.gsub!("Z03_SENDING_SITE") { |match| DOD }

statement, results, status = nil, nil, nil

begin
	#run the query
	statement = connection.createStatement
	has_results = statement.execute(sql)
	ret = "<h4>DoD Z03 Failure Alert - Checking for the Time Period<br>#{start_date} to #{end_date}<br><br></h4>"

	if (has_results)
		results = statement.getResultSet
		results.next

		success_count = results.getInt("success_count")
		failure_count = results.getInt("failure_count")
		total_count = results.getInt("total")

		if (total_count > 0)
			failure_pct = ((failure_count.to_f/total_count)*100).round
			success_pct = 100 - failure_pct

			if (total_count >= min_z03_required)
				ret += "<table class=\"display\"><th>Successful Z03 Count</th><th>Failed Z03 Count</th><th>Total Z03s Received</th><th>Success Pct</th><th>Failure Pct</th></tr>"
				ret += "<tr class=\"odd\"><td>#{success_count}</td><td>#{failure_count}</td><td>#{total_count}</td><td>#{success_pct}%</td><td>#{failure_pct}%</td></tr>"
				ret += "</table><br>"
				status = "GREEN"

				if (failure_pct >= alert_pct)
					status = "RED"
				else
					if (last_known_status.eql?("RED"))
						if (failure_pct <= clearing_pct)
							status = "GREEN"
						else
							status = "RED"
						end
					end
				end
			else
				#	use the last known status
				status = last_known_status
				ret += "<br><br><span class=\"#{status.downcase}_light\">The query did not return a significant sample so we are using the last known status #{status}.</span><br><br>"
			end
		else
			#	use the last known status
			status = last_known_status
			ret += "<br><br><span class=\"#{status.downcase}_light\">The query did not return any results for the time period so we are using the last known status #{status}.</span><br><br>"
		end

		ret += "\n<span class=\"status\">\n__#{status}_LIGHT__\n</span>"
	else
		ret += "<span class=\"red_light\">The query did not return any results for the time period.</span>"
	end
rescue => ex
		raise ex
ensure
	results.close() unless results.nil?
	statement.close() unless statement.nil?
end

ret
