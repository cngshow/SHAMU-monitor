require 'java'
require './jobs/jars/metrics-data-service.jar'

java_import 'shamu.introscope.metricsdataservice.MetricsDataService' do |pkg, cls|
  'JMetricsDataService'
end

class MetricsDataService

  def initialize(end_point, user_name, password)
    @metric_data_service_j = JMetricsDataService.new(end_point, user_name, password) unless user_name.nil?
    @metric_data_service_j = JMetricsDataService.new(end_point) if user_name.nil?
  end

  def get_metric_data(agent_regex, metric_regex, start_time, end_time, data_frequency)
    #corresponds to getMetricData
    time_slice_grouped_or_result_set_metric_data_converter(@metric_data_service_j.getMetricData(agent_regex, metric_regex, start_time, end_time, data_frequency))
  end

  def get_live_metric_data(agent_regex, metric_prefix)
    #corresponds to getLiveMetricData
    time_slice_grouped_or_result_set_metric_data_converter(@metric_data_service_j.getLiveMetricData(agent_regex, metric_prefix))
  end

  def get_top_n_metric_data(agent_regex, metric_regex, start_time, end_time, data_frequency, top_n_count, decreasing_order = false)
     #corresponds to getTopNMetricData
    time_slice_grouped_or_result_set_metric_data_converter(@metric_data_service_j.getTopNMetricData(agent_regex, metric_regex, start_time, end_time, data_frequency, top_n_count, decreasing_order))
  end

  private

  @metric_data_service_j = nil

  #returns an array whose that looks like [some_start_time1,some_end_time1,[value1,value2,value3,...,value_n1],some_start_time2,some_end_time2,[value1,value2,value3,...,value_n12],...]
  #one would expect that if the initial query was well thought out (the periodicity evenly divides into the time under query) that the value array
  #will be of size one
  def time_slice_grouped_or_result_set_metric_data_converter(time_slice_metric_data_array)
    r_val = []
    time_slice_metric_data_array.each do |tmd|
      start_time = Time.at(tmd.getTimesliceStartTime.getTime.getTime/1000)
      end_time = Time.at(tmd.getTimesliceEndTime.getTime.getTime/1000)
      values = []
      metric_data_array = tmd.getMetricData
      metric_data_array.each do |md|
        values << md.getMetricValue
      end
      r_val << [start_time,end_time, values]
    end
    r_val
  end

end