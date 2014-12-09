class DataSharingController < ApplicationController
  skip_before_filter :login_required

  def list_introscope_data
    xml = JobLogEntry.introscope_alerts
    respond_to do |wants|
      wants.html {render :text => xml}
    end
  end
end
