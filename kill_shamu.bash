java -jar ./lib/jars/jruby-complete-1.6.7.2.jar -e 'pid_file = "./log/pid.txt";unless File.exists?(pid_file);  puts "SHAMU is not up"; exit 0; end; pid= `cat ./log/pid.txt`;kill_string = "/bin/kill -9 #{pid}"; puts "Attempting: #{kill_string}";system("#{kill_string}");puts "done!"; system ("rm #{pid_file}")'