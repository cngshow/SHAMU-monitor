#!/u01/dev/ruby_1.8.7/bin/ruby
require 'job_data'
require 'java'

module ShamuExternal

  class JavaRunner

    def self.get_lambda
      lambda do |arguments|
        begin
          java_classpath = arguments.shift
          java_class = arguments.shift #java_class = "gov.va.shamu.ExampleReport"
          java_import 'java.net.URLClassLoader'
          java_import 'java.net.URL'
          java_import 'java.io.File'
          java_import 'java.lang.String'
          java_classpath = java_classpath.split(',').map { |path| File.new(path).toURL }
          my_jar_urls = java_classpath.to_java(URL)
          url_clazz_loader = URLClassLoader.new(my_jar_urls)
          clazz = url_clazz_loader.loadClass(java_class)
          instance = clazz.newInstance
          pool = JobData.ora_pool
          conn = pool.get_connection
          Thread.current[:audit_pool] = pool
          Thread.current[:audit_conn] = conn #giving visibility to the job watchdog.  If this job takes too long the watchdog will cleanup.
          $logger.debug("Connection type is " + conn.getClass.to_s)
          instance.setConnection(conn)
          $logger.debug("Connection set!")
          arguments.each do |arg|
            $logger.debug("The arg is #{arg}")
          end
          result = instance.doWork(arguments.to_java(String))
          result
        rescue => ex
          return "Sorry run failed! " + ex.backtrace.join("\n").to_s
        ensure
          begin #always wrap your ensure block in a begin .. end block (exceptions interfere with job watchdog tagging!)
            pool.return_connection(conn) unless pool.nil? #if the job watch dog kills then pool and conn are nil.
          rescue => ex
            $logger.info("Error in job's ensure block! " + ex.to_s)
          end
        end
      end
    end

  end
end

ShamuExternal::JavaRunner.get_lambda
