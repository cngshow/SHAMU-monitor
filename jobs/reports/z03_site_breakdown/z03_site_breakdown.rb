#!/u01/dev/ruby_1.8.7/bin/ruby
require 'rubygems'
require 'orderedhash'
require './jobs/ruby/lib/utilities'
require 'time'
require 'ftools'

class Z03_Site_Breakdown
  
  def self.load_data(directory)
    files = Dir.entries(directory)
    files.map!{|e| directory + '/' + e}
    files.reject!{|e| ! File.file?(e)}
    date = nil
    site_id = nil
    site_name = nil
    count = nil
    weekly_data = Hash.new
    cnt = 0
    
    files.each do |data_file|
      File.open(data_file, 'r') do |file_handle|
        file_handle.read.each_line do |line|
          if (line =~ /RESULTS FOR: (\d{8})/)
            date = $1
          end
          
          if (line =~ /\s*(\d{3})\s*\|\s*(.*?)\s*\|\s*(\d+)/)
            site_id = $1
            site_name = $2
            count = $3
            hash_key = site_name + " [" + site_id + "]"
            weekly_data[hash_key] = {} unless weekly_data.has_key?(hash_key)
            weekly_data[hash_key][Time.parse(date)] = count.to_i
          end
        end
      end
    end

    weekly_data
  end
  
  def self.build_html(weekly_data, template)
    email_template = Utilities::FileHelper.file_as_string(template)

    if (email_template =~ /<\!--SITE_EXPANSION_BEGIN-->(.*)<\!--SITE_EXPANSION_END-->/m)
      site_substitution = $1 * weekly_data.keys.length
      email_template.gsub!(/<\!--SITE_EXPANSION_BEGIN-->.*<\!--SITE_EXPANSION_END-->/m, site_substitution)
    end

    idx = 1
    start_date = nil
    end_date = nil
    
    weekly_data.keys.sort.each{|site|
      email_template.sub!("#SITE_NAME#", site)
      email_template.sub!("#GREENBAR#", idx % 2 == 0 ? "even" : "odd")
      email_template.sub!("#ROW_NUMBER#", idx.to_s)
      
      weekly_data[site].keys.sort.each {|daily|
        email_template.sub!("#DAY_LABEL#", daily.strftime('%a %b %d'))
        daily_cnt = weekly_data[site][daily]
        daily_cnt = "<span style=\"color:red\"><b>0</b></span>" if daily_cnt == 0 
        email_template.sub!("#DAY_COUNT#", daily_cnt.to_s)
        start_date = daily.strftime('%a %b %d') if idx == 1 && start_date.nil?
        end_date = daily.strftime('%a %b %d') if idx == 1
      }
      idx = idx + 1
    }
    
    #set the reporting period into the H1 section by reporting the first and last record in the hash
    email_template.gsub!("#START_DATE#", start_date)
    email_template.gsub!("#END_DATE#", end_date)
    email_template
  end
end

weekly_data = Z03_Site_Breakdown.load_data(ARGV[0])
puts Z03_Site_Breakdown.build_html(weekly_data, ARGV[1])
