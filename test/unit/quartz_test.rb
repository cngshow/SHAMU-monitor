require "test/unit"
require 'java'
require "./lib/jars/shamu_quartz.jar"
require "./lib/jars/quartz-all-2.1.0.jar"
require "./lib/jars/slf4j-api-1.6.4.jar"
require "./lib/jars/slf4j-jdk14-1.6.4.jar"
require "./lib/jars/jcl-over-slf4j-1.6.4.jar"
require "./lib/jars/commons-exec-1.1.jar"
require "./lib/whenever_parser"

java_import 'va.shamu.quartz.SHAMUScheduler' do |pkg, cls|
  'JSchedule'
end

class QuartzTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
     @scheduler = JSchedule.getInstance
     @scheduler.start #call from the job engine!
     bob = "whenever --load-file ./test/support_scripts/test_schedule.rb 2>&1 |tee"
     @cron_output = `#{bob}` #this works (tee) cuz we have cyqwin)
     @job_data = WheneverParse.new(@cron_output)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
     @scheduler.stop #call from the job engine!
     @scheduler.clearJobs
  end

  def test_cron_expressions
    schedules_and_commands = @job_data.get_schedules_and_commands
    valid = nil
    schedules_and_commands.each do |elem|
      cron_expression = elem[0]
      #cron_expression = "billy" #just to see it fail!
      current_valid = JSchedule.isValidExpression(cron_expression)
      #puts current_valid
      valid = valid | current_valid
    end
    assert(valid)
  end

  def test_job_executes
    system('rm test_file') #or File.unlink file_name
    command = "jruby ./test/support_scripts/create_file.rb"
    cron_expression = "0 * * * * ?" #every minute
    @scheduler.scheduleJob(cron_expression,command, 90)
    puts "sleeping"
    sleep 90
    puts "awake!"
    assert(File.exists?("./test_file"),"The test file is not there!  OH NO!")
  end
end