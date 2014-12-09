#string constants
Z06 = "RSP_Z06"
VHA = "VHACHDR.MED.VA.GOV"
DOD = "DODCHDR.HA.OSD.GOV"

#this method initiates the tracking hash with default counts for each agency for the reporting period
def init_tracking_hash(end_date, lookback)
  hash = {}

  lookback.times.to_a.reverse.each do |days_back|
    date_string = (end_date - (days_back*60*60*24)).strftime("%Y%m%d")
    hash[date_string] = {}
    hash[date_string][:dod] = {:z06_total => 0, :z03_algy => 0, :z03_pharm => 0, :z03_total => 0}
    hash[date_string][:vha] = {:z06_total => 0, :z03_algy => 0, :z03_pharm => 0, :z03_total => 0}
  end
  hash
end

def get_sql(lookback)
  sql = %{
    select created_date,
        sending_site,
        sum(z06_total) as z06_total,
        sum(pharmacy_count) as pharmacy_count,
        sum(allergy_count) as allergy_count,
        sum(pharmacy_count + allergy_count) as z03_total
    from (
        select to_char(a.created_date,'yyyymmdd') as created_date,
            a.sending_site as sending_site,
            count(*) as z06_total,
            0 as pharmacy_count,
            0 as allergy_count
        from chdr2.audited_event a
        where a.event_type = 'RSP_Z06'
        and   a.created_date between trunc(sysdate) - #{lookback} and trunc(sysdate)
        group by to_char(a.created_date,'yyyymmdd'), a.sending_site

        union all

        select to_char(a.created_date,'yyyymmdd') as created_date,
            a.sending_site as sending_site,
            0 as z06_total,
            sum(REGEXP_COUNT(a.message_content, '<RDS_O13>')) as pharmacy_count,
            sum(REGEXP_COUNT(a.message_content, '<ORU_R01>')) as allergy_count
        from chdr2.audited_event a
        where a.event_type = 'RSP_Z06'
        and   a.created_date between trunc(sysdate) - #{lookback} and trunc(sysdate)
        and   a.message_content not like '%<BTS.1>0%'
        group by to_char(a.created_date,'yyyymmdd'), a.sending_site
    )
    group by created_date, sending_site
    order by created_date, sending_site desc
  }
  sql
end

#arg1 is the lookback in days
lookback = ARGV.shift.to_i

#compute the start and end dates based on Time.now and the lookback (midnight to midnight)
end_date = Time.now
start_date = Time.at(end_date - (lookback*60*60*24))

#initiate the tracking hash
@tracking_hash = init_tracking_hash(Time.at(end_date - (60*60*24)), lookback)

#begin processing...
statement, results = nil, nil

begin
  ret = "<div class=\"rpt\">"
  ret += "<h4>Z06 Batch Update Breakdown - Checking from<br>midnight on #{start_date.strftime("%Y%m%d")} to midnight on #{end_date.strftime("%Y%m%d")}<br><br></h4>"

  #run the total counts query to see if we have any data to report on
  statement = connection.createStatement
  has_results = statement.execute(get_sql(lookback))

  if (has_results)
    results = statement.getResultSet

    while (results.next) do
      created_date = results.getString("created_date")
      sending_site = results.getString("sending_site").eql?(VHA) ? :vha : :dod
      z06_total = results.getInt("z06_total")
      pharmacy_count = results.getInt("pharmacy_count")
      allergy_count = results.getInt("allergy_count")
      z03_total = results.getInt("z03_total")

      #set the counts into the tracking hash
      @tracking_hash[created_date][sending_site][:z06_total] = z06_total
      @tracking_hash[created_date][sending_site][:z03_algy] = allergy_count
      @tracking_hash[created_date][sending_site][:z03_pharm] = pharmacy_count
      @tracking_hash[created_date][sending_site][:z03_total] = z03_total
    end

    #begin writing out the table
    ret += "<table class=\"display\">"
    ret += "<th style=\"width:10%\">Batch Update Date</th><th style=\"width:10%\">Sending Site</th><th style=\"width:10%\">Z06 Message Count</th><th>Embedded Allergy Count</th><th>Embedded Pharmacy Count</th><th>Total Embedded Allergy/Pharmacy</th></tr>"

    #iterate the tracking has creating a row for each date/sending site in the hash
    @tracking_hash.each_key { |date|
      dod_hash = @tracking_hash[date][:dod]
      vha_hash = @tracking_hash[date][:vha]
      classname = date.to_i % 2 == 0 ? "even" : "odd"
      ret += "<tr class=\"#{classname}\"><td>#{date}</td><td>VHA</td><td>#{vha_hash[:z06_total]}</td><td>#{vha_hash[:z03_algy]}</td><td>#{vha_hash[:z03_pharm]}</td><td>#{vha_hash[:z03_total]}</td></tr>"
      ret += "<tr class=\"#{classname}\"><td>&nbsp;</td><td>DOD</td><td>#{dod_hash[:z06_total]}</td><td>#{dod_hash[:z03_algy]}</td><td>#{dod_hash[:z03_pharm]}</td><td>#{dod_hash[:z03_total]}</td></tr>"
    }

    #close out the table
    ret += "</table><br>"
  else
    ret += "<br><br><h2>No Z06 Batch Updates Were Sent by Either Agency During this Reporting Period</h2>"
  end
  #close off the rpt div
  ret += "</div><br><br>"
rescue => ex
  raise ex
ensure
  results.close() unless results.nil?
  statement.close() unless statement.nil?
end

#return the report html
ret
