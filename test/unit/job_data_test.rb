require "test/unit"
require 'java'
require './lib/job_data'
require '../lib/PST_logger'
require '../lib/prop_loader'


class JobDataTest < Test::Unit::TestCase

  $connect_string = 'oracle_env'

  def setup
    setup_props
    if $logger.nil?
      $logger = PSTLogger.new("./test/test_log.log", true)
      #$logger = PSTLogger.new('c:\temp\test_log.log')
    end
    #while true
    #    $logger.info("Hello!")
    #end
    @creds = oracle_credentials
  end

  def teardown

  end

  def test_failed_connection
    begin
      exception = false
      connected = JobData.connect_to_oracle("bob", @creds[1])
    rescue => ex
      puts ex.to_s
      exception = true
    end
    assert(!exception, "Exception should not occur in failed connection with bad username")
    assert(!connected[0],"Connection should fail for bad username")
    puts connected[1]
  end

  def test_connection_after_failed_connection
    connected = nil
    begin
      exception = false
      fred_logged_in = false
      begin
        connected = JobData.connect_to_oracle("fred", @creds[1])
        fred_logged_in = connected[0]
      rescue => ex
        puts "Intended logging failure occured! " + ex.to_s
      end
      connected = JobData.connect_to_oracle(@creds[0], @creds[1])
    rescue => ex
      puts ex.to_s
      exception = true
    end
    oracle_id = JobData.oracle_id
    ora_pass = JobData.oracle_password
    assert(!fred_logged_in)
    assert(oracle_id.eql?(@creds[0]))
    assert(ora_pass.eql?(@creds[1]))
    assert(connected[0])
    assert(!exception)

    #test that re - connections can occur
    connect = JobData.connect_to_oracle_with_current_ID
    assert(connect[0], "Reconnection test.")

    connect = JobData.connect_to_oracle(@creds[0], @creds[1])
    assert(connect[0], "Reconnection test by the same user.")
  end

  def test_connection
    connected = nil
    begin
      exception = false
      connected = JobData.connect_to_oracle(@creds[0], @creds[1])
    rescue => ex
      puts ex.to_s
      exception = true
    end
    oracle_id = JobData.oracle_id
    ora_pass = JobData.oracle_password
    assert(oracle_id.eql?(@creds[0]))
    assert(ora_pass.eql?(@creds[1]))
    assert(connected[0])
    assert(!exception)

    #test that re - connections can occur
    connect = JobData.connect_to_oracle_with_current_ID
    assert(connect[0], "Reconnection test.")

    connect = JobData.connect_to_oracle(@creds[0], @creds[1])
    assert(connect[0], "Reconnection test by the same user.")
  end

  private

  def oracle_credentials
    creds = nil
    File.open('./test/oracle_password.txt', 'r') do |file_handle|
      file_handle.read.each_line do |line|
        creds = line.chomp.split(',')
      end
    end
    return creds
  end

  def setup_props
    begin
      if $application_properties.nil?
        $application_properties = PropLoader.load_properties('./pst_dashboard.properties')
      end
    rescue
      puts $!.to_s
      Process.exit
    end
  end

end