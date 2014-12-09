require 'net/http'
require 'rexml/document'
require 'time'

period = ARGV[0]
relative_time = ARGV[1]

url = 'http://apmmom1prd.aac.va.gov:8082/data/query?agentRegex=.*&metricRegex=.*HDR2_WRITES.*CHDR%3AMessage+Count&relativeTime=RELATIVE_TIME&period=PERIOD_IN_SECONDS&format=xml'

url.gsub!("RELATIVE_TIME", relative_time)
url.gsub!("PERIOD_IN_SECONDS", period)
puts url
response = Net::HTTP.get_response(URI.parse(url))
hdr_writes_xml = response.body
hdr_data = {}

if (response.is_a? Net::HTTPOK)
  hdr_writes_document = REXML::Document.new(hdr_writes_xml)
  time = nil
  hdr_writes_document.root.each_element do |datapoint| # each <order> in <orders>
    datapoint.each_element do |node|
      if node.has_elements?
        node.each_element do |child|
          #introscope xml does not do this (at least for this query...)
          #puts "#{child.name}: #{child.attributes['desc']}"
        end
      else
        # here we need to extract end-timestamp and value
        #puts "#{node.name}: #{node.text}***"
        time = Time.parse(node.text) if node.name.strip.eql?("end-timestamp")
        hdr_data[time] = node.text.to_i if node.name.strip.eql?("value")
      end
    end
  end
else
  #failure do not complete processing
  puts hdr_writes_xml
end

hdr_data.keys.sort.each do |time|
  puts "At time #{time} there were #{hdr_data[time]} writes!"
end

#p hdr_writes_xml