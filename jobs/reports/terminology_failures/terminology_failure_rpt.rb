require 'time'
require './jobs/reports/terminology_failures/terminology_util'
require './lib/prop_loader'

def find_ingredients(str, hash)
  regex = /(?:GMR ALLERGY INGREDIENT.*?<OBX\.5><CE\.1>(.+?)<\/CE\.1><CE\.2>(.+?)<\/CE\.2>)/

  #regex2 = /(?:.*GMR ALLERGY INGREDIENT.*<CE\.2>DRUG.*?<\/CE\.2>.*?<CE\.1>GMR ALLERGY.*?<\/CE\.1>.*?<CE\.1>(.*?)<\/CE\.1><CE\.2>(.*?)<\/CE\.2>)/
  find_recurse(str, regex, hash)
end

def find_classes(str, hash)
  regex = /(?:GMR ALLERGY CLASS.*?<OBX\.5><CE\.1>(.*?)<\/CE\.1><CE\.2>(.*?)<\/CE\.2>)/
#(?:(?:.*?GMR ALLERGY CLASS.*?)<CE\.2>DRUG.*?<\/CE\.2>.*?<CE\.1>GMR ALLERGY.*?<\/CE\.1>.*?<CE\.1>(.*?)<\/CE\.1><CE\.2>(.*?)<\/CE\.2>)/
  find_recurse(str, regex, hash)
end

def find_recurse(str, regex, hash)
  if(str =~ regex)
    hash[$1.to_s] = $2.to_s
    recurse_string = str.sub(regex, "")
    find_recurse(recurse_string, regex, hash)
  else
    return hash
  end
end

def calcSuccessPct(success, failure)
  tot = success + failure
  p = success / tot.to_f unless tot == 0
  p = 0 if tot == 0
  (((p*10000).round)/100.to_f).to_s
end

begin
  @dod_site_hash = PropLoader.load_properties("./jobs/reports/terminology_failures/dodSites.properties")
  va_site_ids_array  = ARGV.shift.split(",").map { |e| e.strip }
  dod_site_ids_array = ARGV.shift.split(",").map { |e| e.strip }
  @top_failures      = ARGV.shift.to_i
  frequency          = ARGV.shift.downcase.to_sym
  current_time       = Time.now

  case frequency
    when :daily
      @start_date = (current_time - 24*60*60).strftime("%m/%d/%Y")
      @end_date   = current_time.strftime("%m/%d/%Y")
    when :weekly
      @start_date = (current_time-7*24*60*60).strftime("%m/%d/%Y")
      @end_date   = current_time.strftime("%m/%d/%Y")
    when :monthly
      current_time = current_time.to_a
      @start_date  = Time.local(current_time[5], current_time[4] - 1, 1).strftime("%m/%d/%Y")
      @end_date    = (Time.local(current_time[5], current_time[4], 1)).strftime("%m/%d/%Y")
    when :range
      @start_date = ARGV.shift
      @end_date   = ARGV.shift
    else
      return "Invalid frequency argument passed for #{frequency.to_s}"
  end
#return @start_date.to_s + " -- " + @end_date.to_s
#hash holding the site information
  @va_site_hash = Hash.new

#get the list of site ids and names for reporting purposes
  statement     = connection.createStatement

  if (statement.execute(@site_name_sql))
    results = statement.getResultSet

    #iterate the results pulling the site information and set it into a hash
    while (results.next)
      site_id                = results.getString("site_id")
      site_name              = results.getString("site_name")
      @va_site_hash[site_id] = site_name
    end

    return "Unable to retrieve site information from the institution table...this should not happen" if @va_site_hash.keys.empty?
  end

#instantiate the terminology_totals class variable for storing the data
  @terminology_totals               = {}
  @terminology_totals[:va_to_dod]   = {}
  @terminology_totals[:dod_to_va]   = {}
  @failure_hash                     = {}
  @failure_hash[:terminology_match] = []
  @failure_hash[:site_match]        = []

#ensure that the start and end dates are Time objects for comparison
  @start_date                       = Time.parse(@start_date.to_s)
  @end_date                         = Time.parse(@end_date.to_s)

#define regex for allergy and fill drug code and drug name match groups
  terminology_FILL_regex = /<RXE\.2><CE\.1>(.*?)<\/CE\.1><CE\.2>(.*?)<\/CE\.2>.*?<CE\.3>RXNORM<\/CE\.3>/
  terminology_ALGY_regex = /(?:GMR ALLERGY GENERIC DRUG.*?<OBX\.5><CE\.1>(.*?)<\/CE\.1><CE\.2>(.*?)<\/CE\.2>)|(?:(?!.*GMR ALLERGY GENERIC DRUG.*)<CE\.2>DRUG.*?<\/CE\.2>.*?<CE\.1>GMR ALLERGY.*?<\/CE\.1>.*?<CE\.1>(.*?)<\/CE\.1><CE\.2>(.*?)<\/CE\.2>)/
  terminology_ALGY_INGREDIENT_regex = /(?:GMR ALLERGY INGREDIENT.*?<OBX\.5><CE\.1>(.*?)<\/CE\.1><CE\.2>(.*?)<\/CE\.2>)|(?:(?!.*GMR ALLERGY INGREDIENT.*)<CE\.2>DRUG.*?<\/CE\.2>.*?<CE\.1>GMR ALLERGY.*?<\/CE\.1>.*?<CE\.1>(.*?)<\/CE\.1><CE\.2>(.*?)<\/CE\.2>)/
  terminology_ALGY_CLASS_regex = /(?:GMR ALLERGY CLASS.*?<OBX\.5><CE\.1>(.*?)<\/CE\.1><CE\.2>(.*?)<\/CE\.2>)|(?:(?!.*GMR ALLERGY CLASS.*)<CE\.2>DRUG.*?<\/CE\.2>.*?<CE\.1>GMR ALLERGY.*?<\/CE\.1>.*?<CE\.1>(.*?)<\/CE\.1><CE\.2>(.*?)<\/CE\.2>)/

#setup the variables for both directions (dod_to_va and va_to_dod)
  @dod_failures_algy, @dod_failures_fill = 0, 0
  @vha_failures_algy, @vha_failures_fill = 0, 0
  setup = { :totals => @success_count_sql, :va_to_dod => @va_to_dod_sql, :dod_to_va => @dod_to_va_sql }

  setup.keys.each do |direction|
    sql = setup[direction]

    #set up the SQL to execute
    sql.gsub!("START_DATE") { |match| @start_date.strftime("%Y%m%d") }
    sql.gsub!("END_DATE") { |match| @end_date.strftime("%Y%m%d") }

    if (direction.eql?(:va_to_dod))
      site_ALGY_regex = /<OBR\.3>.*?<EI\.2>(\d{3}).*?<\/EI\.2><\/OBR\.3>/
      site_FILL_regex = /<ORC\.3>.*?<EI\.2>(\d{3}).*?<\/EI\.2><\/ORC\.3>/
    else
      site_ALGY_regex = /<OBX\.15><CE\.1>(.*?)<\/CE\.1>/
      site_FILL_regex = /<ORC\.17><CE\.1>(.*?)<\/CE\.1>/
    end

    #execute sql for terminology failures for the date range passed
    has_results = statement.execute(sql)

    if (has_results)
      results = statement.getResultSet
      while (results.next)
        event_type = results.getString("event_type")

        #if we are executing the totals SQL then set the values into variables and continue looping
        if (direction.eql?(:totals))
          d = results.getString("direction")
          c = results.getInt("z03_cnt")

          if (d.eql?("dod_to_va"))
            @dod_success_algy = c if event_type.eql?("ALGY")
            @dod_success_fill = c if event_type.eql?("FILL")
          else
            @vha_success_algy = c if event_type.eql?("ALGY")
            @vha_success_fill = c if event_type.eql?("FILL")
          end

          next
        else
          #increment the failure counts based on direction and event type
          if (direction.eql?(:dod_to_va))
            @dod_failures_algy += 1 if event_type.eql?("ALGY")
            @dod_failures_fill += 1 if event_type.eql?("FILL")
          else
            @vha_failures_algy += 1 if event_type.eql?("ALGY")
            @vha_failures_fill += 1 if event_type.eql?("FILL")
          end
        end

        #we are pulling terminology failures so get the message id, event_type and z03 payload
        message_id = results.getString("message_id")
        z03_xml    = results.getString("z03_xml")

        cui_code, cui_name = nil, nil
        ingredients_hash, classes_hash, cui_data_hash = {}, {}, {}

        #match based on event type pulling the drug code and name from the
        if (event_type.eql?("ALGY"))
          z03_xml =~  terminology_ALGY_regex
          cui_code = $1.to_s.strip + $3.to_s.strip
          cui_name = $2.to_s.strip + $4.to_s.strip
          ingredients_hash = find_ingredients(z03_xml, {})
          classes_hash = find_classes(z03_xml, {})
          cui_data_hash[cui_code] = {:cui_name => cui_name, :ingredients => ingredients_hash, :classes => classes_hash}
        else
          z03_xml =~ terminology_FILL_regex
          cui_code = $1.to_s.strip + $3.to_s.strip
          cui_name = $2.to_s.strip + $4.to_s.strip
          cui_data_hash[cui_code] = {:cui_name => cui_name}
        end

        if (cui_code.empty?)
          @failure_hash[:terminology_match] << message_id
          next
        end

        #increment the all sites count
        increment_count(direction, :all_sites, cui_data_hash, event_type, message_id)

        #get the site and increment the count
        r = site_FILL_regex

        if (event_type.eql?("ALGY"))
          r = site_ALGY_regex
        end

        if ($1.nil?)
          @failure_hash[:site_match] << message_id
          next
        end

        #increment site specific information
        site_id = $1.strip
        increment_count(direction, site_id, cui_data_hash, event_type, message_id)
      end
    else
      return "No terminology failures occurred for the time period #{@start_date} to #{@end_date}"
    end
  end

  #begin writing the results into the html template
  html_template = HEADER.clone.sub("#START_DATE#", @start_date.strftime("%m/%d/%Y")).sub("#END_DATE#", (@end_date - (60*60*24)).strftime("%m/%d/%Y"))

#write the summary stats table
  html_template << SUMMARY_TABLE_START.clone
#write the 2 summary rows
  { :va_to_dod => { :title => "VHA CHDR", :success_algy => @vha_success_algy, :success_fill => @vha_success_fill, :failure_algy => @vha_failures_algy, :failure_fill => @vha_failures_fill },
    :dod_to_va => { :title => "DOD CHDR", :success_algy => @dod_success_algy, :success_fill => @dod_success_fill, :failure_algy => @dod_failures_algy, :failure_fill => @dod_failures_fill } }.each_pair do |k, v|
    data = SUMMARY_ROW.clone
    data.sub!("#GREENBAR#", k.eql?(:va_to_dod) ? "odd" : "even")
    data.sub!("#SENDING_SITE#", v[:title])
    sAlgy = v[:success_algy].to_i
    sFill = v[:success_fill].to_i
    fAlgy = v[:failure_algy].to_i
    fFill = v[:failure_fill].to_i

    data.sub!("#SUCCESS_COUNT_ALGY#", sAlgy.to_s)
    data.sub!("#FAILURE_COUNT_ALGY#", fAlgy.to_s)
    data.sub!("#SUCCESS_PCT_ALGY#", calcSuccessPct(sAlgy, fAlgy))
    data.sub!("#SUCCESS_COUNT_FILL#", sFill.to_s)
    data.sub!("#FAILURE_COUNT_FILL#", fFill.to_s)
    data.sub!("#SUCCESS_PCT_FILL#", calcSuccessPct(sFill, fFill))

    tot = sAlgy + sFill + fAlgy + fFill
    data.sub!("#TOTAL_COUNT#", tot.to_s)
    data.sub!("#SUCCESS_PCT#", calcSuccessPct(sFill + sAlgy, fFill + fAlgy))
    html_template << data
  end

#close off the table
  html_template << SUMMARY_TABLE_END.clone

  #write the tables for each direction
  { :va_to_dod => va_site_ids_array, :dod_to_va => dod_site_ids_array }.each_pair do |direction, site_ids_array|
    data = @terminology_totals[direction]
    html_template << write_html(data, :all_sites, direction)
    site_ids_array.each do |site_id|
      html_template << write_html(data, site_id, direction)
    end
  end

  html_template << FOOTER.clone
  html_template

rescue => ex
  error = ex.backtrace.join("\n").to_s
  return  error
end
