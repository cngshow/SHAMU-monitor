#a simple controller that given some key returns some value.  I simple way for jobs to ask SHAMU questions...
class KeyValueController < ApplicationController
	skip_before_filter :login_required

	def fetch
    raise "local requests only!" unless request.local?
    user_request = params["request"]
    result = ""
    case
      when user_request.downcase.eql?("credentials")
        result = JobData.oracle_id + "|" + JobData.oracle_password
      else
        result = "unknown request : #{user_request}"
    end
    respond_to do |wants|
    			wants.html {render :text => result}
    end
	end
end