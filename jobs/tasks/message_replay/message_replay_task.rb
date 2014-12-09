#return "gem home is " + ENV['gem_home']

load './jobs/tasks/message_replay/replay_hash_helper.rb'
require './jobs/ruby/helpers/logger_helper.rb'
load './jobs/tasks/message_replay/message_replay_helper.rb'
include JobLogging
include ReplayHashHelper
include ReplayHelpers
require 'time'

$connection = connection

#pull out the replay message file that defines the replay task being run, create the corresponding hash file for tracking,
#load the file, and include the module to expose the defined methods in the file

job_code = ARGV.shift
replay_message_file = ARGV.shift
load replay_message_file
include ReplayMessages

#create the replay hash and log based on the path of the replay file coupled with the job code
path = replay_message_file.split("/")
path.pop
path = path.join("/") + "/"
@replay_check_file = path + job_code + ".hash"

#log levels (debug, info, warn, error, fatal)
log_level = ARGV.shift
@log_path = path + job_code + ".log"
$logger = get_logger(@log_path, job_code, log_level, true)
$logger.debug("********************************************************************")
$logger.debug("********************************************************************")
$logger.debug("********************************************************************")
$logger.debug("********************************************************************")

statement, results = nil, nil

begin
  init

  $logger.debug("**** job arguments from argv = " + ARGV.inspect + " ****")

  #pull out the additional, required replay task arguments
  @top_fault_count = ARGV.shift.to_i
  $rails_root = ARGV.shift
  @spring_beans_path = ARGV.shift
  start_date = ARGV.shift
	end_date = ARGV.shift
	$service_bus_env = ARGV.shift.upcase
  $scrub = ! $service_bus_env.upcase.eql?("PROD")
  hash_trim_days_back = ARGV.shift.to_i
  @replay_group_count = ARGV.shift.to_i
  @replay_pause = ARGV.shift.to_i # set to zero if we are not sleeping and running as fast as we can
	@replay_max = ARGV.shift.to_i # this is the maximum number of messages that can be replayed for this run

  replay_days_back = ARGV.shift.to_i
  use_dates = ARGV.shift.to_i
  raise "Invalid boolean value passed in 'use_dates'. Valid values are 0 as false and 1 as true" unless (use_dates == 0 or use_dates == 1)

  @max_service_bus_errors = ARGV.shift.to_i
  @message_replay_limit = ARGV.shift.to_i
  $message_id_tag = ARGV.shift

  #set any additional arguments that are replay task specific into the additional_arguments global variable
  $additional_arguments = ARGV
  $logger.debug("Before post_init")
  return "Spring Application context failed to initialize. Check log #{@log_path}." unless post_init
  $logger.debug("after post_init")
  initialize_replayed_message_hash(hash_trim_days_back)
  $logger.debug("after initialize_replayed_message_hash")

  if (use_dates == 0)
    #this is a scheduled run (from cron) get the last run from the replay hash
    supporting_data = @replay_check_hash[:supporting_data]

    #if last date is not found then get the current date trimmed to midnight and back if off the replay_days_back
    if (supporting_data.nil?)
      $logger.debug("*** no replay hash dates-- setting start and end dates based on current time and replay_days_back")
      @replay_check_hash[:supporting_data] = {}
      supporting_data = @replay_check_hash[:supporting_data]
      end_date = @current_time
      start_date = (@current_time - (replay_days_back*24*60*60))
    else
      $logger.debug("*** replay hash dates exist!!!")
      #pull the finish time from the hash and use it as the start time of this run
      end_date = @current_time
      start_date = supporting_data[:replay_run_end_date]

      if (start_date + (replay_days_back*24*60*60) < @current_time)
        $logger.debug("*** resetting start date due to current time being greater than finish time of last run + days back")
        start_date = @current_time - (replay_days_back*24*60*60)
      end
    end

    #stick the start and end dates in the hash
    supporting_data[:replay_run_start_date] = start_date
    supporting_data[:replay_run_end_date] = end_date
    $logger.debug("*** running from " + start_date.strftime("%Y%m%d") + " to " + end_date.strftime("%Y%m%d"))
  end

  #ensure that the start and end dates are Time objects for comparison
  $logger.debug("About to set start date / end date")
  @start_date = Time.parse(start_date.to_s)
  @end_date = Time.parse(end_date.to_s)
  $logger.debug("Date range = #{@start_date} to #{@end_date}")

  return "Invalid start/end dates passed. The start date must be before the end date and the dates cannot be in the future.  Date range = #{@start_date} to #{@end_date}" if (@start_date > @end_date || @start_date > @current_time || @end_date > @current_time)
  $logger.debug("about to call get sql")
  sql = get_sql
  $logger.debug(sql)

  #run the query
  statement = $connection.createStatement
  has_results = statement.execute(sql)
  $logger.debug("Query results? ....... " + has_results.to_s)
  result = ""
  @sql_result_row_count = 0

  if (has_results)
    results = statement.getResultSet

    #iterate the results pulling the event type, message, and fault information and call the appropriate method
    #based on the fault code
		replayed_messages_count = 0
		@display_max_termination_message = false

    while (results.next)
      @sql_result_row_count += 1
      message_id = results.getString("message_id")
      event_type = results.getString("event_type")
      fault_code = results.getString("fault_code")
      fault_detail = results.getString("fault_detail")
      message_content = results.getString("message_content")

      #record the number of individual fault codes being processed
      @tracking_hash[:fault_code_counts][fault_code] = 0 if (@tracking_hash[:fault_code_counts][fault_code].nil?)
      @tracking_hash[:fault_code_counts][fault_code] += 1

      #check the message id to see if it has been replayed previously
      replay_count = get_replay_count(message_id) - 1

      if ((replay_count < @message_replay_limit) && call_replay?(fault_code, fault_detail))
        #$scrub out PII if $scrub is true (in testing mode)
        scrubPII(message_content) if $scrub

        #track the fault detail
        track_faults(fault_code, fault_detail)

        #replay the message
        replay_success = replay_message(message_id, event_type, message_content)

        #increment the replayed messages counter if we successfully replayed the message
        replayed_messages_count = replayed_messages_count + (replay_success.eql?(1) ? 1 : 0)
        @tracking_hash[:replay][message_id] = [@direction, event_type, replay_success]
			end

			if (replayed_messages_count == @replay_max)
				@display_max_termination_message = true
			end

      break if ((@service_bus_error_count >= @max_service_bus_errors) || (replayed_messages_count == @replay_max))
    end
  end

  #set the report results to return
  $logger.info("**************************************** calling get results ****************************************")
  result = get_report_result

  #write the attempted replayed messages to disk
  processing_complete
rescue => ex
  return ex.backtrace.join("\n")
ensure
	results.close() unless results.nil?
	statement.close() unless statement.nil?
end

$logger.debug("*** job complete ***")
#return the results
result