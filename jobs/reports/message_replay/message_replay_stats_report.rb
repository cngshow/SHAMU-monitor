VHA       = "VHACHDR.MED.VA.GOV"
DOD       = "DODCHDR.HA.OSD.GOV"

@fault_detail_matches = {
    :hdrII_constraint_violated => ["906", "HDR constraint violated - duplicate insert attempt failed", /HDRII_CONSTRAINT_VIOLATED/, 0],
    :transaction_terminated_abnormally => ["900", "CHDR System Error - transaction terminated abnormally", /Transaction terminated abnormally on VA CHDR server/, 0],
    :VETSNotFoundException => ["903", "Terminology Error - VETSNotFoundException", /VETSNotFoundException/, 0],
    :jta_failure_on_commit => ["906", "CHDR System Error - JTA failure on commit", /JTA failure on commit;/, 0]
}

def write_failure_table
  idx = 0
  ret = "<table class=\"display\"><tr>"
  ret += "<th style=\"text-align:center\">Replayed Message Fault Code</th>"
  ret += "<th style=\"text-align:center\">Replayed Message Fault Detail</th>"
  ret += "<th style=\"text-align:center\">Replay Failure Count</th></tr>"

  @fault_detail_matches.each_pair { |key, arr|
    if (arr[3].to_i > 0)
      idx += 1
      ret += "<tr class=\"#{idx % 2 > 0 ? "odd" : "even"}\">"
      ret += "<td style=\"text-align:center\">#{arr[0].to_s}</td>"
      ret += "<td style=\"text-align:left\">#{arr[1].to_s}</td>"
      ret += "<td style=\"text-align:right\">#{arr[3].to_s}</td></tr>"
    end
  }

  ret += "</table><br>"
  ret
end

def get_replay_counts_sql(start_date, end_date, message_replay_limit)
  replay_counts_sql = %{
    select REPLAY_ATTEMPTS
        count(*) as total_replayed,
        nvl(sum(case when B.FAULT_CODE is not null then 1 else 0 end),0) as failed_replay
    from chdr2.audited_event a, chdr2.audited_event b
    where a.message_id = b.correlation_id
    and   a.CREATED_DATE between to_date('#{start_date}','yyyymmdd') and to_date('#{end_date}','yyyymmdd')
    and   a.sending_site = '#{DOD}'
    and   a.receiving_site = '#{VHA}'
    and   a.message_id like '%_r_%'
    }

  #append the max failure limit columns based on the argument passed to the replay count SQL
  replay_attempt_sql = ""
  @replay_attempt_colname = []

  message_replay_limit.times do |i|
    @replay_attempt_colname << "replay_#{i + 1}_count"
    replay_attempt_sql += "sum(case when a.message_id like '%_r_#{i + 1}' then 1 else 0 end) as replay_#{i + 1}_count,\n"
  end

  replay_counts_sql.gsub!("REPLAY_ATTEMPTS") { |match| replay_attempt_sql }
  replay_counts_sql
end

def get_replay_failure_sql(start_date, end_date)
  replay_failure_sql = %{
    select b.fault_code as fault_code,
      b.fault_detail as fault_detail
    from chdr2.audited_event a, chdr2.audited_event b
    where a.message_id = b.correlation_id
    and   a.CREATED_DATE between to_date('#{start_date}','yyyymmdd') and to_date('#{end_date}','yyyymmdd')
    and   a.sending_site = '#{DOD}'
    and   a.receiving_site = '#{VHA}'
    and   a.message_id like '%_r_%'
    and b.fault_code is not null
    }
  replay_failure_sql
end

start_date = ARGV.shift
end_date = ARGV.shift
message_replay_limit = ARGV.shift.to_i + 1

replay_counts_sql = get_replay_counts_sql(start_date, end_date, message_replay_limit)
replay_failure_sql = get_replay_failure_sql(start_date, end_date)

#begin report output generation
ret = "<h4>Message Replay Summary Statistics for the Time Period<br>#{start_date} to #{end_date}<br><br></h4>"
statement, results = nil, nil

begin
  #run the query replay count SQL
  statement = connection.createStatement
  has_results = statement.execute(replay_counts_sql)

  if (has_results)
    results = statement.getResultSet
    results.next

    total_replayed = results.getInt("total_replayed")
    failed_replay = results.getInt("failed_replay")
    failure_pct = 0
    failure_pct = ((failed_replay.to_f/total_replayed)*100).round if total_replayed > 0
    success_pct = 100 - failure_pct

    ret += "<table class=\"display\"><tr><th>Replayed Message Count</th><th>Failed Replays</th><th>Replay Success Percentage</th>"
    @replay_attempt_colname.each { |col|
      ret += "<th>" + col.gsub("_", " ").capitalize + "</th>"
    }

    #close out the header row
    ret += "</tr>"

    #write out the summary row
    ret += "<tr class=\"odd\"><td>#{total_replayed}</td><td>#{failed_replay}</td><td>#{success_pct}%</td>"

    @replay_attempt_colname.each { |col|
      ret += "<td>" + results.getInt(col).to_s + "</td>"
    }
    ret += "</tr></table>"
  end

  # retrieve the failure fault details for a detail table
  results.close() unless results.nil?
  has_results = statement.execute(replay_failure_sql)
  ret += "<br><br><br>"
  ret += "<h4>Message Replay Failure Fault Details<br><br></h4>"

  if (has_results)
    results = statement.getResultSet

    while results.next
      fault_code = results.getString("fault_code")
      fault_detail = results.getString("fault_detail")

      match = false
      @fault_detail_matches.each_pair do |key, arr|
        if (fault_detail =~ arr[2] && fault_code.eql?(arr[0]))
          @fault_detail_matches[key][3] += 1
          match = true
          break
        end
      end

      if (! match)
        key = fault_detail.to_sym
        @fault_detail_matches[key] = [fault_code,fault_detail,Regexp.new("^#{fault_detail}$"), 1]
      end
    end

    #write out the table
    ret += write_failure_table
  else
    ret += "There were no failed Z04s to report on. All replayed messages succeeded."
  end
rescue => ex
  raise ex
ensure
  results.close() unless results.nil?
  statement.close() unless statement.nil?
end

ret
