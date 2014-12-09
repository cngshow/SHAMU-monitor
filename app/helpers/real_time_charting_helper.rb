require 'prop_loader'

module RealTimeChartingHelper
  @@props = nil

  def is_ie_browser
    request.env['HTTP_USER_AGENT'].downcase =~ /msie/
  end

  def render_params
    @@props = PropLoader.load_properties($application_properties['realtime_params']) if @@props.nil?
    param_output = ""
    is_ie = is_ie_browser

    @@props.each_pair do |k,v|
      if (is_ie)
        param_output << "<param name=\"#{k}\" value=\"#{v}\"> \n"
      else
        param_output << "#{k}=\"#{v}\" \n"
      end
    end
    param_output
  end
end
