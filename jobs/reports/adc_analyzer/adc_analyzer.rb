#!/u01/dev/ruby_1.8.7/bin/ruby
require 'java'
require 'rubygems'
require './jobs/jars/gruff_rmagick4j.jar'
require 'gruff'
require 'orderedhash'
require './jobs/ruby/lib/utilities'
require 'lib/time_utils'
require 'ftools'

class ADC_Analyzer
  SEC_PER_HOUR = 60*60
  SEC_PER_DAY = SEC_PER_HOUR * 24
  
  @@adc_hash = OrderedHash.new
  
  def self.load_data(file)
    File.open(file, 'r') do |data_file|
      data_file.read.each_line do |line|
        line.chomp!
        if (line =~ /\d{4}-.*/)
          data = line.split(',')
          time = data[0].split('-')
          #key is the day, value is an arrray [#ADC activated on the day, #total ADC on the day.]
          @@adc_hash[Time.local(time[0],time[1],time[2])] = [data[1].to_f,data[2].to_f]
        end        
      end
    end
   # fill_missing_days
  end
  
  def self.trim_days(days_kept)
    sorted = @@adc_hash.sort
    return @@adc_hash if (sorted.length < days_kept)
    trimmed = OrderedHash.new
    count = 0
    sorted.reverse.each do
      |key_value|
      trimmed[key_value[0]] = key_value[1]
      count = count + 1
      return trimmed if (count == days_kept)
    end
  end
  
  def self.draw_graph(size,file_location,data_hash,label_modulus,best_fit_line_array,best_fit_days_out, file_end = "")
    the_graph = Gruff::Line.new(size)
    #the_graph = Gruff::Bar.new(size)
    the_graph.theme = {:colors => ["green", "red"],:marker_color => 'black',:background_colors => %w(cornsilk white)}
    the_graph.title = "ADC graph for " << data_hash.keys.sort[0].strftime('%m/%d/%y') << " to " << data_hash.keys.sort[-1].strftime('%m/%d/%y')    
    the_graph.data("ADC Activations",data_hash.keys.sort.map{|k| data_hash[k][1]})
    best_fit_data = Array.new(data_hash.keys.length + best_fit_days_out)
    best_fit_data[0] = best_fit_line_array[1].to_i
    best_fit_data[-1] = (best_fit_line_array[0]*(data_hash.keys.length + best_fit_days_out) + best_fit_line_array[1]).to_i

#    best_fit_data[-best_fit_days_out - 1] = (best_fit_line_array[0]*(data_hash.keys.length) + best_fit_line_array[1]).to_i
#    best_fit_data[-1] = (best_fit_line_array[0]*(data_hash.keys.length + best_fit_days_out) + best_fit_line_array[1]).to_i

    the_graph.data("Best Fit Line", best_fit_data)
    final_time = Time.at(data_hash.keys.sort[-1].to_i + best_fit_days_out*SEC_PER_DAY).strftime('%m/%d/%y')
    labels = ADC_Analyzer.label_hash(data_hash,label_modulus)
    labels[data_hash.keys.length + best_fit_days_out - 1] = final_time
    the_graph.labels = labels
    the_graph.hide_dots = true
    the_graph.line_width = 2
    the_graph.write(file_location)
  end
  
  def self.label_hash(data_hash, day_mod)
    count = 0
    labels = Hash.new
    foo = data_hash.keys.sort
    data_hash.keys.sort.each do
      |time|
      labels[count] = time.strftime('%m/%d/%y') if ((count % day_mod) == 0) 
      count = count + 1
    end
    labels
  end
  
  #see "Statistics for Business and Economics 9th edition (Anderson, Sweeney, Williams) page 560 for formulas.
  def self.best_fit_line(hash_data)
    x_val = hash_data.keys.sort
    sum_xi_yi = 0.0
    sum_xi = 0.0
    sum_yi = 0.0
    sum_xi_sq = 0.0
    #The x values are instances of the Time class.  As we are guaranteed to have a data point in sequence for each day (from start to finish)
    #W.L.O.G we will allow x_sub_i to equal i
    for i in 1..(x_val.length)
      sum_xi_yi = sum_xi_yi + i*hash_data[x_val[i-1]][1]
      sum_xi = sum_xi + i
      sum_yi = sum_yi + hash_data[x_val[i-1]][1]
      sum_xi_sq = sum_xi_sq + i*i
    end
    slope = (sum_xi_yi - sum_xi*sum_yi/x_val.length)/(sum_xi_sq - sum_xi*sum_xi/x_val.length)
    y_intercept = sum_yi/x_val.length - slope*sum_xi/x_val.length
    [slope,y_intercept]
  end
  
  def self.calculate_adc_count_date(best_fit_line,adc_count, start_date)
    days_till_count_reached = (adc_count.to_f - best_fit_line[1]) / best_fit_line[0]
    Time.at(start_date.to_i + (days_till_count_reached*SEC_PER_DAY).to_i)
  end
  
  def self.number_with_delimiter(number, delimiter=",")
    number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
  end
  
  def self.get_current_adc_count
  	[@@adc_hash.keys.sort[-1],@@adc_hash[@@adc_hash.keys.sort[-1]][1].to_i]
  end

end

#load the data from the text file
ADC_Analyzer.load_data(ARGV[0])
#split the lookback days and labels from the argument list
days_labels = ARGV[1].split(",").map{|x| [x.split(":")[0].to_i, x.split(":")[1].to_i] }
#pull out the milestones that will be calculated using the lookbacks set above
milestones = ARGV[2].split(",").map{|x| x.to_i}
#pull out the prediction period from the arguments to see where the ADC count will be in a given number of days at the current run rate
prediction_period = ARGV[3].to_i
#pull out the size of the image that will be generated
size = ARGV[4]
#pull out the directory to write the public images for reference in the html
img_dir = ARGV[5]
#build the directories for the current run
current_time = Time.now.strftime('%Y%m%d')
shamu = ARGV[6] + "/" + current_time
Dir::mkdir(img_dir) unless FileTest::directory?(img_dir)
img_dir = img_dir + "/#{current_time}"
Dir::mkdir(img_dir) unless FileTest::directory?(img_dir)
#pull out the path to the email template file being used
email_template = Utilities::FileHelper.file_as_string(ARGV[7])

if (email_template =~ /<\!--MILESTONE_EXPANSION_BEGIN-->(.*)<\!--MILESTONE_EXPANSION_END-->/m)
  milestone_substitution = $1 * milestones.length
  email_template.gsub!(/<\!--MILESTONE_EXPANSION_BEGIN-->.*<\!--MILESTONE_EXPANSION_END-->/m,milestone_substitution)
end

if (email_template =~ /<\!--DAYS_EXPANSION_BEGIN-->(.*)<\!--DAYS_EXPANSION_END-->/m)
  days_substitution = $1 * days_labels.length
  email_template.gsub!(/<\!--DAYS_EXPANSION_BEGIN-->.*<\!--DAYS_EXPANSION_END-->/m, days_substitution)
end

email_template.gsub!("#PREDICTION_PERIOD_GSUB#", prediction_period.to_s)
email_template.gsub!("#SHAMU_GSUB#", shamu)
email_template.gsub!("#FINAL_DATE_GSUB#",ADC_Analyzer.get_current_adc_count[0].strftime('%m/%d/%y'))
email_template.gsub!("#CURRENT_ADC_COUNT_GSUB#",ADC_Analyzer.get_current_adc_count[1].to_s)

days_labels.each do |day_label|
  data = ADC_Analyzer.trim_days(day_label[0])
  best_fit_line = ADC_Analyzer.best_fit_line(data)
  ADC_Analyzer.draw_graph(size,"#{img_dir}/adc_graph_#{day_label[0]}.gif", data, day_label[1], best_fit_line, prediction_period)
  
  email_template.sub!("#DAYS_GIF#", day_label[0].to_s)
  email_template.sub!("#DAYS_DESC#", day_label[0].to_s)
  
  milestones.each do |milestone|
    date = ADC_Analyzer.calculate_adc_count_date(best_fit_line, milestone, data.keys.sort[0])
    email_template.sub!("#MILESTONE#", ADC_Analyzer.number_with_delimiter(milestone))
    email_template.sub!("#MILESTONE_DATE#", date.strftime('%m/%d/%y %H:%M:%S ') << TimeUtils.zone_abbreviation(date))

#    puts "For the #{day_label[0]} day chart we will have a #{milestone} adc patients at " << date.to_s
  end
end

puts email_template


#2350.91976787258 -- 486855.595006242
#y = 2350.91976787258 x + 486855.595006242
#1000000 =  2350.91976787258 x + 486855.595006242
#(1000000 - 486855.595006242)  / 2350.91976787258




#  def self.fill_missing_days
#    time = nil
#    @@adc_hash.keys.sort.each do
#      |time_key|
#      if time.nil?
#        time = time_key
#        next
#      end
##      puts time_key.to_s
##      puts time.to_s
##      puts "-------"
#      if ((time_key - time) > SEC_PER_DAY)
#        ADC_Analyzer.add_days(time, time_key)
#      end
#      time = tie_key
#    end
#    a = @@adc_hash
#    puts "Hi"
#  end
#  
#  def self.add_days(start_time, end_time)
#    da_hash = @@adc_hash
#    num_days_to_fill = (((end_time - start_time) + SEC_PER_HOUR)/(SEC_PER_DAY)).to_i - 1
#    #the 60*60 is to add an hour in case of daylight savings time (causing the loss of an hour)
#    adc_stat = @@adc_hash[start_time].clone
#    for i in 1..num_days_to_fill
#      adc_stat[0] = 0
#      adc_stat[2] = true
#      @@adc_hash[end_time - i*SEC_PER_DAY] = adc_stat
#    end
# end
