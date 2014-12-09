require 'job_data'
require 'thread'

class RealTimeChartingController < ApplicationController
  skip_before_filter :login_required, :only => [:real_time_data, :real_time_charting_run]
  before_filter :only_beta, :except => :real_time_data
  @@sql=Utilities::FileHelper.file_as_string($application_properties['realtime_sql'])
  layout :assign_layout
  @@query_time = nil
  @@last_result = nil?
  @@time_mutex = Mutex.new
  @@DATABASE_ERROR = "DATABASE_ERROR"
  
  def real_time_data  
    #@@sql = Utilities::FileHelper.file_as_string($application_properties['realtime_sql']) if @@sql.nil?
    @real_time_charting_layout = true
    if (Boolean(SystemProp.get_value('suspend_rtc')))
      @real_time_data = "TERMINATE"
      return
    end
    @@time_mutex.synchronize {
        query_cache_time = 1.minute.ago
        seconds = query_cache_time.sec
        query_cache_time = query_cache_time - seconds# round down to the whole minute
        $logger.debug("@@query_time : " + @@query_time.to_s)
        $logger.debug("query_cache_time : " + query_cache_time.to_s)
        if(query_cache_time.to_s.eql?(@@query_time.to_s))
          parts = @@last_result.split('#')
          @@last_result = parts[0] + "#" + seconds.to_s unless @@last_result.eql?(@@DATABASE_ERROR)
          @real_time_data = @@last_result
          $logger.debug("returning the cached real time data.")
          return
        else
            @@query_time = query_cache_time
        end
        sql = prepare_sql#sets up the sql with the proper times
        @real_time_data = get_real_time_string(sql)
        oracle_seconds = @real_time_data.split('#')[1]
        delta = (oracle_seconds.to_i - seconds).abs
        $logger.info("real_time_data: oracle seconds = " + oracle_seconds.to_s + " : Rails seconds = " + seconds.to_s)
        @@last_result = @real_time_data
    }
  end
  
  def real_time_charting_pref
    if (session[:real_time_charts].nil?)
      session[:real_time_charts] = {:va_chart_types => ['VA_TOTALS'], :dod_chart_types => ['DOD_TOTALS'], :chart_history => '10 minutes', :chart_size => 'Small'}
    end
    @va_chart_types = session[:real_time_charts][:va_chart_types]
    @dod_chart_types = session[:real_time_charts][:dod_chart_types]
    @chart_history = session[:real_time_charts][:chart_history]
    @chart_size = session[:real_time_charts][:chart_size]   
    @page_hdr = "Real-time Charting - Preferences Filter"
    @suspend_button_text = Boolean(SystemProp.get_value('suspend_rtc')) ? 'Enable Real Time Charting' : 'Suspend Real Time Charting'
    msg = ''
    
    if (! JobEngine.instance.started?)
      msg = 'The Job Engine must be running in order to view real time charting. Please contact a SHAMU System Administrator.'
    elsif (Boolean(SystemProp.get_value('suspend_rtc')))
      msg = 'Real Time Charting has been suspended. Please contact a SHAMU System Administrator.'
    end
    
    if (! msg.empty?)
      flash.now[:error] = msg
    end
    
  end
  
  def real_time_charting_suspend
    suspend = params[:commit]
    suspend = suspend.eql?('Suspend Real Time Charting')
    SystemProp.set_prop("suspend_rtc", suspend.to_s)
    redirect_to real_time_charting_pref_path
  end
  
  def real_time_charting_run
    @real_time_charting_layout = true
    @page_hdr = "Real-time Charting - Live"
    
    @va_types_string = set_chart_types(params['va_chart_types'])
    @dod_types_string = set_chart_types(params['dod_chart_types'])
    
    @chart_types = '' #java script ensure that at least @va_types_string or @dod_types_string has a selection
    @chart_types = @va_types_string + "," if !@va_types_string.empty?
    @chart_types << @dod_types_string if !@dod_types_string.empty?
    
    session[:real_time_charts][:va_chart_types] = params['va_chart_types']
    session[:real_time_charts][:dod_chart_types] = params['dod_chart_types']
    session[:real_time_charts][:chart_history] = params['chart_history']
    session[:real_time_charts][:chart_size] = params['chart_size']
    @va_chart_types = @va_types_string.split(',')
    @dod_chart_types = @dod_types_string.split(',')
    @chart_history = session[:real_time_charts][:chart_history]
    @chart_size = session[:real_time_charts][:chart_size]
    
    @chart_width = @chart_size.eql?('Small') ? '600' : (@chart_size.eql?('Medium') ? '800' : '1000')
    @chart_height =  @chart_size.eql?('Small') ? '371' : (@chart_size.eql?('Medium') ? '494' : '618')
  end
  
  def init
    @real_time_charting_layout = false
  end


  def assign_layout
    if (@real_time_charting_layout)
      "real_time_charting_layout"
    else
      "application"
    end
  end
  
  private
  
  @@last_oci_error = nil;
  @@pool = nil
  
  def set_chart_types(type_array)
    return '' if type_array.nil?
    type_array.join(',')
  end
  
  def prepare_sql
    sql = String.new(@@sql)
    epoch = @@query_time.to_i * 1000
    query_start_local_tz = Time.at(@@query_time.to_i)
    year = query_start_local_tz.year.to_s
    month = query_start_local_tz.strftime('%m') 
    day = query_start_local_tz.strftime('%d') 
    hour = query_start_local_tz.strftime('%H') 
    minute = query_start_local_tz.strftime('%M') 
    bdate = year + month + day + hour + minute
    sql.gsub!('BDATE',bdate)
    sql.gsub!('EPOCHDATE',epoch.to_s)
    sql
  end
  
  def get_real_time_string(sql)
    ######################## BEGIN IMPORTANT NOTE ########################
    # The following link takes you to the oracle connection pool documentation
    #   http://docs.oracle.com/cd/B28359_01/java.111/e11990/allclasses-noframe.html
    ######################## END IMPORTANT NOTE ########################
    database_error = false
    pool = JobData.ora_pool
    conn = nil

    if (pool.nil?)
      database_error = true
      $logger.error("Real time charting could not get a reference to the database connection pool.")
    else
      begin
        conn = pool.get_connection
        #raise "broken!"
      rescue
        $logger.error("Real time charting could not get a database connection. The error returned was #{$!}.")
        database_error = true
      end
    end

    if (database_error)
      $logger.error("returning #{@@DATABASE_ERROR}")
      data = @@DATABASE_ERROR
      return data
    end

    data = ''     
    oracle_second = nil

    begin
      statement = conn.createStatement
      results = statement.executeQuery(sql)
      #results.beforeFirst

      while results.next do
        row = results.getObject('server_sec').to_s + ','
        row += results.getObject('mi').to_s + ','
        row += results.getObject('agency_msg').to_s + ','
        row += results.getObject('sec05').to_s + ','
        row += results.getObject('sec10').to_s + ','
        row += results.getObject('sec15').to_s + ','
        row += results.getObject('sec20').to_s + ','
        row += results.getObject('sec25').to_s + ','
        row += results.getObject('sec30').to_s + ','
        row += results.getObject('sec35').to_s + ','
        row += results.getObject('sec40').to_s + ','
        row += results.getObject('sec45').to_s + ','
        row += results.getObject('sec50').to_s + ','
        row += results.getObject('sec55').to_s + ','
        row += results.getObject('sec60').to_s

        time_info_array = add_time_info(row)
        data <<  time_info_array[0]
        data << '|'
        oracle_second = time_info_array[1]
      end
      data.chop!
      pool.return_connection(conn)
    rescue Exception => e
      $logger.error("Exception thrown from UCPPool! -- " + e.to_s)
      $logger.error("returning #{@@DATABASE_ERROR}")
      data = @@DATABASE_ERROR
      database_error = true
    end

    data << '#' << oracle_second unless database_error
    $logger.debug("returning fresh real time data.")
    data
  end
  
  def add_time_info(row)#update (7-19-2010) also handles the time on the oracle server.
    #row might look like this: 32.0,201006211508,DOD_Z03,0.0,0.0,1.0,0.0,0.0,1.0,0.0,1.0,2.0,0.0,0.0,0.0
    #first element is the second number on the oracle server.
    data = row.split(',')
    second = data.shift
    date = data.shift
    type = data.shift
    date = Time.parse(date).to_i
    time_incr = 5
    r_val = type + ','
    data.each do |element|
      r_val << (date + time_incr).to_s << ',' << element << ','
      time_incr = time_incr + 5
    end
    $logger.debug(r_val)
    r_val.chop!
    [r_val,second.to_s]
  end
  
end
