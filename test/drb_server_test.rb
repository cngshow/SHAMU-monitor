require 'drb'
require 'thread'

def drb_listen
  @drb_thread = Thread.new do
    shared_hash = {:response=>nil}
    DRb.start_service('druby://localhost:61676',shared_hash)
    puts 'Listening for connection...'
    DRb.thread.join
  end
end

drb_listen
@drb_thread.join

