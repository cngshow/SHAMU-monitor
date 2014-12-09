require 'test/unit'

module KMA
  def kma
    "I am a #{self.class}!"
  end
end

class MyTest < Test::Unit::TestCase
  include KMA

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup

  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # Fake test
  def test_fail
    tc = kma
    puts tc
    # To change this template use File | Settings | File Templates.
    puts $LOAD_PATH.to_s
    assert(!tc.nil?)
    #fail('Not implemented')
  end
end