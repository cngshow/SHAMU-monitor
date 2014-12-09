require 'job_data'

module ShamuExternal

  class RubyRunner

    def get_lambda
      lambda do |arguments|
        begin
          pool = JobData.ora_pool
          conn = pool.get_connection
          Thread.current[:audit_pool] = pool
          Thread.current[:audit_conn] = conn #giving visibility to the job watchdog.  If this job takes too long the watchdog will cleanup. con_type = conn.java_class.to_s
          ruby_file_lambda = arguments.shift
          arguments.unshift(conn)
          $logger.debug("The ruby file is: " + ruby_file_lambda)
          lambda_code = Utilities::FileHelper.file_as_string(ruby_file_lambda)
          the_lambda = instance_eval(lambda_code)
          $logger.debug("The ruby lambda is " + the_lambda.to_s)
          return the_lambda.call(arguments)
        rescue => ex
          return "Execution of #{ruby_file_lambda} failed. Reason: " + ex.to_s
        ensure
          begin #always wrap your ensure block in a begin .. end block (exceptions interfere with job watchdog tagging!)
            unless (pool.nil?)
              pool.return_connection(conn) #if the job watch dog kills then pool and conn are nil.
              $logger.debug("Connection returned to the pool!")
            end
          rescue => ex
            $logger.error("Error in job's ensure block! A connection may not have been returned!" + ex.to_s)
          end
        end
      end
    end

  end
end

ShamuExternal::RubyRunner.new.get_lambda
