require './jobs/ruby/lib/job'
require 'java'

java_import 'java.lang.System' do |pkg, cls|
  'JSystem'
end
java_import 'java.lang.Runtime' do |pkg, cls|
  'JRuntime'
end
java_import 'java.io.OutputStreamWriter' do |pkg, cls|
  'JWrite'
end
java_import 'java.io.InputStreamReader' do |pkg, cls|
  'JRead'
end
java_import 'java.io.BufferedWriter' do |pkg, cls|
  'JBWrite'
end
java_import 'java.io.BufferedReader' do |pkg, cls|
  'JBRead'
end
java_import 'java.io.File' do |pkg, cls|
  'JFile'
end

module ShamuExternal
  class SQLInvokerInternal

    def get_job_result
      lambda { |arguments|
        #get the file separator
        fs = JSystem.getProperties.getProperty("file.separator")
        credentials = [arguments.shift,arguments.shift]
        rails_root = arguments.shift
        connect_string = arguments.shift
        sql_plus_string = arguments.shift
        sql_script = arguments.shift
        arguments = arguments.join(" ")
        arguments = arguments.split('>') #checking for a possible file redirect here
        redirect_file = arguments[1]
        arguments = arguments[0]
        result = ""
      #execute sql script and store results
      #PL/SQL procedure successfully completed.
        execute_cmd = "#{sql_plus_string} #{credentials[0]}@#{connect_string} @#{sql_script} #{arguments} 2>&1"
        run_time = JRuntime.getRuntime()
        exec_method = run_time.java_method :exec, [Java::java.lang.String[], Java::java.lang.String[], Java::java.io.File ]
        process = exec_method.call(execute_cmd.split, nil, JFile.new(rails_root))
        j_outputStream = process.getOutputStream
        j_inputStream = process.getInputStream
        j_writer = JBWrite.new(JWrite.new(j_outputStream))
        j_writer.write(credentials[1],0,credentials[1].length)
        j_writer.close
        j_reader = JBRead.new(JRead.new(j_inputStream))
        result = ""
        while ((line = j_reader.readLine) != nil)
          result << line << "\n"
        end
        j_reader.close
        process.waitFor

        unless redirect_file.nil?
          #redirect_file might simply be a file like 'foo.txt' or it
          #might have a directory structure like './my/path/to/foo.txt'.  If the latter occurs we need to make the directory
          #might have a directory structure like './my/path/to/foo.txt'.  If the latter occurs we need to make the directory
          file_parts = redirect_file.split(/\\|\//)
          file_parts.pop #remove the file name
          directory_structure = file_parts.join('/')
          begin
            #FileUtils.mkdir_p directory_structure
            system("mkdir -p #{directory_structure}")
            File.open(redirect_file.strip, 'w') {|f| f.write(result) }
          rescue => ex
            result = "Error: " + ex.to_s
          end
          return ""
        end

        regex = Regexp.new(".*OUTPUT_BELOW:\n{0,1}(.*)OUTPUT_ABOVE:\n{0,1}.*", Regexp::MULTILINE)
        if (result.match(regex))
      #if (result =~ /.*OUTPUT_BELOW:(.*)OUTPUT_ABOVE:.*/m)  #this does not work in jruby with /s, /m or /ms.  What gives?
          result = $1
          return result
        end

        regex = Regexp.new(".*(EMAIL_RESULT_BELOW:.*EMAIL_RESULT_ABOVE:).*", Regexp::MULTILINE)
        if (result.match(regex))
          result = $1
          return result
        end

        regex = Regexp.new(".*(<[hH][tT][mM][lL]>.*<\/[hH][tT][mM][lL]>).*", Regexp::MULTILINE)
        if (result.match(regex))
          result = $1
          return result
        end

        result
      }
    end

  end
end

#from this point on no declaring variables to ensure you do not stomp on anything in SHAMU core!
ShamuExternal::SQLInvokerInternal.new.get_job_result.call(ARGV)
