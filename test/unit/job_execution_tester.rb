require "test/unit"
require './jobs/ruby/lib/job'

class JobExecutionTest < Test::Unit::TestCase
  def test_credentials
    credentials = JobExecutor.get_credentials_http
    puts credentials[0]
    puts credentials[1]
  end
end