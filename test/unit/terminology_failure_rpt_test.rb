require 'test/unit'
require './lib/ucppool'

class NoOp
	def method_missing(meth, *args, &block)
	end
end
$logger=NoOp.new

def oracle_credentials
	creds = nil
	File.open('./test/oracle_password.txt.password', 'r') do |file_handle|
		file_handle.read.each_line do |line|
			creds = line.chomp.split(',')
		end
	end
	return creds
end

class TerminologyFailureRptTest < Test::Unit::TestCase

	# Called before every test method runs. Can be used
	# to set up fixture information.
	def setup
		creds = oracle_credentials
		#PRODUCTION
		ucppool = MyOracleUcpPool.new(creds[0], creds[1], "jdbc:oracle:thin:@//hdr2db4v.aac.va.gov:1569/CHDRP01.AAC.VA.GOV ", 0, 5, 2)
		#get connection from pool
		$connection = ucppool.get_connection()

		@terminology_failure = file_as_string("./jobs/reports/terminology_failures/terminology_failure_rpt.rb")
		ARGV.clear
		ARGV << "556"
		ARGV << "0056"
		ARGV << "20"
		ARGV << "daily"
		ARGV << "20130601"
		ARGV << "20130701"
	end

	# Called after every test method runs. Can be used to tear
	# down fixture information.

	def file_as_string(file)
		rVal = ''
		File.open(file, 'r') do |file_handle|
			file_handle.read.each_line do |line|
				rVal << line
			end
		end
		rVal
	end

	def teardown
		# Do nothing
	end

	# Fake test
	def test_report
		start = Time.now
		begin
			load "./jobs/reports/terminology_failures/terminology_failure_rpt.rb"
			return true
		rescue => ex
			puts ex.to_s
			puts ex.backtrace.join("\n")
			return false
		end

		end_time = Time.now
		puts "elapsed time is " + (end_time - start).to_s
	end
end
