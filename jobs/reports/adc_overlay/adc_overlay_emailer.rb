#!/u01/dev/ruby_1.8.7/bin/ruby
require './jobs/ruby/lib/utilities'

email_template = Utilities::FileHelper.file_as_string(ARGV[0])
images_dir = ARGV[1]
base_url = ARGV[2]
width = ARGV[3]
images = Dir.entries(images_dir).sort.delete_if{|file| file !~ /.*\.jpeg$|.*\.png|.*\.jpg/}
email_template.gsub!("##WIDTH##",width)
email_template =~ /CHARTING_EXPANSION_BEGIN(.*)CHARTING_EXPANSION_END/m
expansion = $1
expansion = expansion*images.size
email_template.gsub!(/CHARTING_EXPANSION_BEGIN#{$1}CHARTING_EXPANSION_END/m,expansion)

images.each { |image| email_template.sub!("##CHART_LOCATION##", base_url + "/" + image)}

puts email_template
