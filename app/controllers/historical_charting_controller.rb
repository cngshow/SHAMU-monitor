require 'json'
require 'time'
require 'orderedhash'

class HistoricalChartingController < ApplicationController		
	skip_before_filter :login_required

	def list_historical_directories
		historical_directory = $application_properties['historical_path']
		historical_url = $application_properties['historical_url']
		directories = Dir.entries(historical_directory)
		directories.reject!{|e| !Regexp.compile('\d{8}').match(e.to_s)}
		directories.map! {|date| Time.parse(date)}
		results = []
		directories.sort.reverse.each { |date|
			
			url = historical_url.clone
			url.gsub!("DATE",date.strftime("%Y%m%d"))
			results.push([date.strftime("%m/%d/%y"),url])
		}
		respond_to do |wants|
			wants.json {render :text => results.to_json}		
			wants.html {render :text => results.to_json}	
		end
	end	
end
