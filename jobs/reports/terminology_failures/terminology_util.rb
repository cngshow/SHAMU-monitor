@va_to_dod_sql = %{
  select b.fault_detail as fault_detail, a.event_type as event_type, a.message_content as z03_xml, a.message_id as message_id
  from chdr2.audited_event a, chdr2.audited_event b
  where a.message_id = b.correlation_id
  and   A.CREATED_DATE BETWEEN TO_DATE ('START_DATE','yyyymmdd') AND TO_DATE ('END_DATE','yyyymmdd')
  and   A.sending_site = 'VHACHDR.MED.VA.GOV'
  and   a.receiving_site = 'DODCHDR.HA.OSD.GOV'
  and   a.event_type in ('FILL','PRES','ALGY')
  and   b.FAULT_DETAIL LIKE '%translation%'
 -- and   rownum < 500
}

@dod_to_va_sql = %{
  select b.fault_detail as fault_detail, a.event_type as event_type, a.message_content as z03_xml, a.message_id as message_id
  from chdr2.audited_event a, chdr2.audited_event b
  where a.message_id = b.correlation_id
  and   A.CREATED_DATE BETWEEN TO_DATE ('START_DATE','yyyymmdd') AND TO_DATE ('END_DATE','yyyymmdd')
  and   a.sending_site = 'DODCHDR.HA.OSD.GOV'
  and   A.receiving_site = 'VHACHDR.MED.VA.GOV'
  and   a.event_type in ('FILL','PRES','ALGY')
  and   b.FAULT_CODE = '903'
 -- and   rownum < 500
}

@success_count_sql = %{
  select 'va_to_dod' as direction,
    'FILL' as event_type,
    count(a.message_id) as z03_cnt
  from  chdr2.audited_event a, chdr2.audited_event b
  where a.message_id = b.correlation_id
  and   A.CREATED_DATE BETWEEN TO_DATE ('START_DATE','yyyymmdd') AND TO_DATE ('END_DATE','yyyymmdd')
  and   A.sending_site = 'VHACHDR.MED.VA.GOV'
  and   a.receiving_site = 'DODCHDR.HA.OSD.GOV'
  and   a.event_type in ('FILL','PRES')
  and   b.fault_detail is null

  union all

  select 'va_to_dod' as direction,
    'ALGY' as event_type,
    count(a.message_id) as z03_cnt
  from  chdr2.audited_event a, chdr2.audited_event b
  where a.message_id = b.correlation_id
  and   A.CREATED_DATE BETWEEN TO_DATE ('START_DATE','yyyymmdd') AND TO_DATE ('END_DATE','yyyymmdd')
  and   A.sending_site = 'VHACHDR.MED.VA.GOV'
  and   a.receiving_site = 'DODCHDR.HA.OSD.GOV'
  and   a.event_type = 'ALGY'
  and   b.fault_detail is null

  union all

  select 'dod_to_va' as direction,
    a.event_type as event_type,
    count(a.message_id) as z03_cnt
  from  chdr2.audited_event a, chdr2.audited_event b
  where a.message_id = b.correlation_id
  and   A.CREATED_DATE BETWEEN TO_DATE ('START_DATE','yyyymmdd') AND TO_DATE ('END_DATE','yyyymmdd')
  and   a.sending_site = 'DODCHDR.HA.OSD.GOV'
  and   A.receiving_site = 'VHACHDR.MED.VA.GOV'
  and   a.event_type in ('FILL','ALGY')
  and   b.fault_detail is null
  group by a.sending_site, a.event_type
}

@site_name_sql = %{
  select a.stationnumber as site_id, a.name as site_name
  from CHDR2.STD_INSTITUTION a, CHDR2.STD_FACILITYTYPE  b
  where a.FACILITYTYPE_ID = b.ID
  and   a.DEACTIVATIONDATE IS NULL
  and   b.ISMEDICALTREATING = 1
  and   length(a.stationnumber) = 3
  and   a.agency_id=1009121 -- VA agency
}

def increment_count(direction, site_id, cui_data_hash, event_type, z03_message_id)
  @terminology_totals[direction][site_id] = {} if @terminology_totals[direction][site_id].nil?
  puts "*************************** Adding #{site_id} to the terminology totals "if @terminology_totals[direction][site_id].nil?

  #initialize the ALGY / PRES-FILL buckets
  et = event_type.eql?("ALGY") ? "ALGY" : "PRES-FILL"
  @terminology_totals[direction][site_id][et] = {} if @terminology_totals[direction][site_id][et].nil?

  #initialize the hash for the given event_type / cui_data_hash
  @terminology_totals[direction][site_id][et][cui_data_hash] = {} if @terminology_totals[direction][site_id][et][cui_data_hash].nil?

  #set the message_id into an array in the totals hash
  @terminology_totals[direction][site_id][et][cui_data_hash][:count] = 0 if @terminology_totals[direction][site_id][et][cui_data_hash][:count].nil?
  @terminology_totals[direction][site_id][et][cui_data_hash][:count] += 1
  @terminology_totals[direction][site_id][et][cui_data_hash][:message_id] = [] if @terminology_totals[direction][site_id][et][cui_data_hash][:message_id].nil?
  @terminology_totals[direction][site_id][et][cui_data_hash][:message_id] << z03_message_id
end

def write_html(data, site, direction)
  ret = ""

  begin
    #get the site name from the appropriate hash based on the direction
    site_hash = direction.eql?(:va_to_dod) ? @va_site_hash : @dod_site_hash
    site_name = site_hash[site].nil? ? site : "#{site} - #{site_hash[site]}"
    algy_site_data, pres_site_data = nil, nil

    #put the allergy and pres-fill data sorted and in separate hashes
    unless (data[site].nil?)
      algy_site_data = data[site]["ALGY"].to_a.sort { |e, f| f[1][:count] <=> e[1][:count] } unless data[site]["ALGY"].nil?
      pres_site_data = data[site]["PRES-FILL"].to_a.sort { |e, f| f[1][:count] <=> e[1][:count] }[0..(@top_failures-1)] unless data[site]["PRES-FILL"].nil?

      #iterate the table data writing the data out as html tables
      { :algy => algy_site_data, :pres_fill => pres_site_data }.each_pair do |et, td|
        if (!td.nil?)
          if (et.eql?(:algy))
            ret += ALGY_TABLE_START.clone
            ret.sub!("#DIRECTION#", direction.eql?(:va_to_dod) ? "VA to DoD" : "DoD to VA")
            ret.sub!("#EVENT_TYPE#", et.eql?(:algy) ? "Allergy" : "PRES-FILL")
            ret.sub!("#SITE_H3#", "Reporting for #{site.eql?(:all_sites) ? "All Sites" : site_name}")
          else
            ret += DRUG_TABLE_START.clone
            ret.sub!("#DIRECTION#", direction.eql?(:va_to_dod) ? "VA to DoD" : "DoD to VA")
            ret.sub!("#EVENT_TYPE#", et.eql?(:algy) ? "Allergy" : "PRES-FILL")
            ret.sub!("#SITE_H3#", "Reporting for #{site.eql?(:all_sites) ? "All Sites" : site_name}")
          end

          idx = 0

          td.each do |cui_data_hash|
            #cui_data_hash.inspect = [{"C0724054"=>{:cui_name=>"Tramadol Hydrochloride, (Ultram)", :ingredients=>{}, :classes=>{}}}, {:count=>2, :message_id=>["DoD00000000265642868", "DoD00000000265723354"]}]

            if (et.eql?(:algy))
              allergen, ingredients, classes = "", "", ""

              cui_data_hash[0].each_pair do |cui_code, cui_hash|
                allergen = "#{cui_code} : #{cui_hash[:cui_name]}"

                cui_hash[:ingredients].each_pair do |cui_code, cui_desc|
                  ingredients += "#{cui_code} : #{cui_desc}<br>"
                end

                cui_hash[:classes].each_pair do |cui_code, cui_desc|
                  classes += "#{cui_code} : #{cui_desc}<br>"
                end
              end

              idx += 1
              row = ALGY_ROW.clone
              row.sub!("#GREENBAR#", idx%2 == 0 ? "even" : "odd")
              row.sub!("#ALLERGEN#", allergen)
              row.sub!("#INGREDIENTS#", ingredients)
              row.sub!("#CLASSES#", classes)
              row.sub!("#COUNT#", cui_data_hash[1][:count].to_s)
            else
              #pharmacy
              pharma_drug = ""

              cui_data_hash[0].each_pair do |cui_code, cui_hash|
                pharma_drug = "#{cui_code} : #{cui_hash[:cui_name]}"
              end

              idx += 1
              row = DRUG_ROW.clone
              row.sub!("#GREENBAR#", idx%2 == 0 ? "even" : "odd")
              row.sub!("#PHARMA_DRUG#", pharma_drug)
              row.sub!("#COUNT#", cui_data_hash[1][:count].to_s)
            end

            ret += row
            break if !et.eql?(:algy) && idx > 0 && cui_data_hash[1][:count] < 5
          end

          #close off the table
          ret += TABLE_END.clone
        else
          ret += BAD_SITE.clone.sub("#SITE_H3#", site.to_s).sub("#EVENT_TYPE#", et.eql?(:algy) ? "Allergies" : "PRES-FILLs")
        end
      end
    else
      #no site data
      if (site.eql?(:all_sites))
        site = "All Sites"
      end
      ret = BAD_SITE.clone.sub("#SITE_H3#", site.to_s).sub("#EVENT_TYPE#", "both allergy and medications")
    end
    ret
  rescue => ex
    return ex.to_s + "\n\n" + ex.backtrace.join("\n")
  end
end

ALGY_TABLE_START = %{
		<div class="site_border">
    <h1>#EVENT_TYPE# Terminology Failures for #DIRECTION#</h1>
    <h3>#SITE_H3#</h3>
    <table class="sample" cellpadding="6" width="800px">
    <tr>
      <th width="20%">Allergen</th>
      <th width="35%">Ingredients</th>
      <th width="35%">Classes</th>
      <th width="10%">Count</th>
    </tr>
}

ALGY_ROW = %{
	<tr class="#GREENBAR#">
		<td align="left" valign="top">#ALLERGEN#</td>
		<td align="left" valign="top">#INGREDIENTS#</td>
		<td align="left" valign="top">#CLASSES#</td>
		<td align="right" valign="top">#COUNT#</td>
	</tr>
}

DRUG_TABLE_START = %{
		<div class="site_border">
    <h1>#EVENT_TYPE# Terminology Failures for #DIRECTION#</h1>
    <h3>#SITE_H3#</h3>
    <table class="sample" cellpadding="6" width="800px">
	<tr>
		<th width="80%">Drug Name</th>
		<th width="20%">Count</th>
	</tr>
}

DRUG_ROW = %{
	<tr class="#GREENBAR#">
		<td align="left">#PHARMA_DRUG#</td>
		<td align="right">#COUNT#</td>
	</tr>
}

TABLE_END = %{
    </table>
		</div>
    <br/><br/>
}

BAD_SITE = %{
		<br/>
    <h3>No data found for #EVENT_TYPE# for site code: #SITE_H3#</h3>
    <br/>
}

HEADER = %{
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
	<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
		<title>Terminology Failure Report</title>
		<style type="text/css">
			html, body {
				color: navy;
				font-size: small;
			}
			div.rpt {
				text-align:  center;
				width: 800px;
				padding-left: 5px;
			}
			h2 {
				text-align: center;
			}
			h3 {
				text-align: left;
			}
			table.sample {
				border: solid;
				border-width: thin;
				border-color: navy;
				background-color: #eee;
			}
			table.sample th {
				text-align: bottom;
				background-color: navy;
				color: white;
			}
			.odd {
				background-color: #fff;
			}
			.even {
				background-color: "transparent";
			}
			div.site_border {
				border: solid;
				border-width: thin;
				border-color: #E8E8E8;
			}
		</style>
	</head>
	<body>
	<div class="rpt">
		<h2>Terminology Failure Report<br>For #START_DATE# thru #END_DATE#</h2>
		The following report breaks down Z03 Clinical Updates that failed terminology that were sent between the VA to DoD
		over the reporting period.
		<br/><br/>
}

FOOTER = %{
	</div>
	</body>
	</html>
}

SUMMARY_TABLE_START = %{
		<div class="site_border">
    <h1>Z03/Z04 Clinical Updates Summary Statistics</h1>
    <table class="sample" cellpadding="6" width="800px">
	<tr>
		<th width="12%">Z03 Sending Site</th>
		<th width="11%">Successful Allergy</th>
		<th width="11%">Failed Allergy</th>
		<th width="11%">Success Allergy Pct</th>
		<th width="11%">Successful Pharmacy</th>
		<th width="11%">Failed Pharmacy</th>
		<th width="11%">Success Pharmacy Pct</th>
		<th width="11%">Total Messages Sent</th>
		<th width="11%">Total Success Pct</th>
	</tr>
}

SUMMARY_ROW = %{
	<tr class="#GREENBAR#">
		<td align="left">#SENDING_SITE#</td>
		<td align="right">#SUCCESS_COUNT_ALGY#</td>
		<td align="right">#FAILURE_COUNT_ALGY#</td>
		<td align="right">#SUCCESS_PCT_ALGY#%</td>
		<td align="right">#SUCCESS_COUNT_FILL#</td>
		<td align="right">#FAILURE_COUNT_FILL#</td>
		<td align="right">#SUCCESS_PCT_FILL#%</td>
		<td align="right">#TOTAL_COUNT#</td>
		<td align="right">#SUCCESS_PCT#%</td>
	</tr>
}

SUMMARY_TABLE_END = %{
    </table>
		</div>
    <br/><br/>
}
