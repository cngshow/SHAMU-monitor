module SystemPropConstants
	SUSPEND='SUSPEND'
end

module Kernel
	def Boolean(string)
		return true if string == true || string =~ /^true$/i
		return false if string == false || string.nil? || string =~ /^false$/i
		raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
	end

end

module ActionView::Helpers::UrlHelper
	def link_to_absolute(relative_string)
		#url_for  :controller => controller, :action =
		host = $application_properties['root_url']
		relative_string.sub!("<a href=\"","<a href=\"#{host}")
		relative_string
	end

end

class ActionController::Request

	#  def ssl?()
	#    puts "RAILS ActionController::Request -- ssl"
	#    https_on = @env['HTTPS']
	#    proto = @env['HTTP_X_FORWARDED_PROTO']
	#    puts "https_on = #{https_on.to_s}, proto = #{proto.to_s}"
	#    #return true
	#    @env['HTTPS'] == 'on' || @env['HTTP_X_FORWARDED_PROTO'] == 'https'
	#
	#  end
	def protocol
		#puts "RAILS ActionController::Request - protocol"
		https = Boolean($application_properties['use_https'])
		https ? 'https://' : 'http://'
	# original definition
	#       ssl? ? 'https://' : 'http://'
	end

end

module Utilities
	class FileHelper
		def FileHelper.file_as_string(file)
			rVal = ''
			File.open(file, 'r') do |file_handle|
				file_handle.read.each_line do |line|
					rVal << line
				end
			end
			rVal
		end
	end

end