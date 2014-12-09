require "test/unit"

class BackTickTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_backtick
    #result = `cd .. && ls`  # verifying that cd can be called in backticks given that Java's exec does not support it.
    result = `jruby -e 'puts "RUN_DATA_BEGIN_" + Time.now.to_s + "_RUN_DATA_END" '`
    puts result
    assert(!result.empty?)
  end

end

#BackTickTest.new.test_backtick