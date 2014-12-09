require 'thread'
#require 'java'
#java_import java.util.concurrent.Executors

class ThreadPool
  def initialize(max_size)
    @pool = []
    @max_size = max_size
    @pool_mutex = Mutex.new
    @pool_cv = ConditionVariable.new
    #@executor = Executors.newFixedThreadPool(max_size)
  end

  def working?
    @pool_mutex.synchronize do
      return !(@pool.size == 0)
    end
    #@executor.isTerminated
  end

  def dispatch(the_lambda, tag, job_code, jle)
    #@executor.submit do
    #  begin
    #    $logger.info("Thread pool has submitted  " + tag)
    #    the_lambda.call(job_code,jle)
    #  rescue =>e
    #    exception(self, e, *[tag,job_code,jle])
    #  end
    #end
    Thread.new do
      Thread.current[:job_code] = job_code
      # Wait for space in the pool.
      @pool_mutex.synchronize do
        while @pool.size >= @max_size
          $logger.info("Pool is full; waiting to run #{[the_lambda,tag,job_code,jle].join(',')}...")
          # Sleep until some other thread calls @pool_cv.signal.
          @pool_cv.wait(@pool_mutex)
        end
      end

      @pool << Thread.current
      begin
        $logger.info("Thread pool is starting to execute " + tag)
        the_lambda.call(job_code,jle)

      rescue => e
        exception(self, e, *[tag,job_code,jle])
      ensure
        @pool_mutex.synchronize do
          ActiveRecord::Base.connection.close #any active record connections associated with this thread must be closed.
          # Remove the thread from the pool.
          @pool.delete(Thread.current)
          # Signal the next waiting thread that there's a space in the pool.
          @pool_cv.signal
        end
      end
    end
  end

  def shutdown
    @pool_mutex.synchronize { @pool_cv.wait(@pool_mutex) until @pool.empty? }
    #@executor.shutdown
  end

  def exception(thread, exception, *original_args)
    # Subclass this method to handle an exception within a thread.
    $logger.error("Exception in thread #{thread}: #{exception}")
    $logger.error(exception.backtrace.join("\n"))
  end
end