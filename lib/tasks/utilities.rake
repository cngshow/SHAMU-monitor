require './lib/prop_loader'
require './lib/job_engine'
require 'rubygems'
require 'helpers'

namespace :utilities do

  desc "Trim the job log"
  task :database_trim => :environment do
    puts "Trim everything older than how many days?  Enter for the default of 90."
    days_back = $stdin.gets
    days_back.chomp!
    days_back = "90" if days_back.eql? ""
    days_back = days_back.to_i
    return if (days_back == 0)
    puts "About to trim the database"
    trimmed = JobLogEntry.clean_up_log days_back
    puts "Done!  I trimmed #{trimmed} records from the database!"
  end

  desc "Get the status of the appropriate trackables for introscope"
  task :introscope_alerts => :environment do
    init
    JobLogEntry.introscope_alerts
  end

  desc "Build up a zip file to upload to UNIX for deploying SHAMU."
  task :deploy_shamu do
    ENV['RUNNER_TASK'] = "true"
    require 'find'
    require 'fileutils'
    include FileUtils
    jar_exists = `jar  2>&1`
    unless (jar_exists =~/^Usage: jar/)
      puts "Java's jar was not found on the path.  Please fix this issue and try again."
      exit 1
    end
    puts "Where should I place the SHAMU zip/war file?  Hit enter for the default of C:\\temp\\SHAMU"
    destination = $stdin.gets
    destination.chomp!
    destination = "C:\\temp\\SHAMU" if destination.eql?("")
    FileUtils.rmtree "#{destination}\\PSTDashboard\\"
    FileUtils.mkdir_p destination
    print "Copying the application located at \"#{Rails.root}\" to #{destination}..."
    comfort_dots
    FileUtils.cp_r(Rails.root, destination)
    FileUtils.rmtree "#{destination}\\PSTDashboard\\zzz_old_code"
    FileUtils.rmtree "#{destination}\\PSTDashboard\\.idea"
    FileUtils.rmtree "#{destination}\\PSTDashboard\\PSTDashboard"
    FileUtils.rmtree "#{destination}\\tmp"
    FileUtils.rmtree "#{destination}\\public\\historical_chart\\data"
    FileUtils.rmtree "#{destination}\\public\\message_traffic_charts*"
    replay_path = "#{destination}\\PSTDashboard\\jobs\\tasks\\message_replay\\"
    replay_path.gsub!("\\", "/")
    #glob only works with unix style paths
    FileUtils.rm Dir.glob(replay_path + "*.hash")
    FileUtils.rm Dir.glob(replay_path + "*.log")

    log_path = "#{destination}\\PSTDashboard\\log\\"
    log_path.gsub!("\\", "/")
    FileUtils.rm Dir.glob(log_path + "*")

    FileUtils.rm("#{destination}\\PSTDashboard\\jobs\\reports\\monthlyADC\\va-chdr-monthly-adc.zip",:force => true)
    FileUtils.rmtree "#{destination}\\public\\historical_charts\\data"
    `"chmod 777  #{destination}\\PSTDashboard\\config\\schedule.rb"`
    `"chmod 777  #{destination}\\PSTDashboard\\config\\schedule.rb.bak"`
    `"dos2unix #{destination}\\PSTDashboard\\config\\schedule.rb"`
    `"dos2unix #{destination}\\PSTDashboard\\config\\schedule.rb.bak"`
    `"dos2unix #{destination}\\PSTDashboard\\config\\commands.txt"`
    comfort_dots(false)
    puts " Done!"
    deployment_loc = "#{destination}\\PSTDashboard\\"
    Dir.chdir(deployment_loc) #all file operations will now take place from here...
    # puts "globbing "#{executables_loc}\\*.bash""
    bash_files = Dir.glob("./*.bash")
    env_hash = setup_environment
    if (env_hash[:type] == :w)
      build_war(env_hash,destination, deployment_loc)
    end
    #print "Replacing windows files with unix files..."
    #comfort_dots
    #Find.find('./') do |f|
    #  FileUtils.mv(f, f[0..f.length - 1 - ".unix".length]) if f =~ /unix$/
    #end
    #comfort_dots(false)
    #puts " Done!"
    if (env_hash[:type] == :m)
      print "Zipping up the files..."
      comfort_dots
      File.delete "#{destination}\\shamu.zip" if File.exists? "#{destination}\\shamu.zip"
      system("cd #{destination} && jar cf shamu.zip PSTDashboard")
      comfort_dots(false)
      puts " Done!"
    end

    print "Removing the directory #{destination}\\PSTDashboard..."
    comfort_dots
    FileUtils.rmtree "#{destination}\\PSTDashboard"
    comfort_dots(false)
    puts " Done!"
    if (env_hash[:type] == :w)
      sftp_shamu_zip("#{destination}\\PSTDashboard.war")
    else
      sftp_shamu_zip("#{destination}\\shamu.zip")
    end
    puts "Do not forget to chmod +x the following files:"
    bash_files.each do |b|
      puts b
    end
    #print out a reminder to chmod +x the bash files
  end


  def init()
    begin
      if $application_properties.nil?
        $application_properties = PropLoader.load_properties('./pst_dashboard.properties')
      end
    rescue
      puts "Failed to load ./pst_dashboard.properties "<< $!
      Process.exit
    end
  end

  def sftp_shamu_zip(file)
    puts "Shall I upload SHAMU to unix? y for yes, anything else is no..."
    input = $stdin.gets.chomp
    if (input.eql?('y'))
      require 'java'
      require './jobs/jars/zehon_file_transfer-1.1.6.jar'
      require './jobs/jars/commons-logging-1.0.4.jar'
      require './jobs/jars/commons-vfs-2.0.jar'
      require './jobs/jars/jsch-0.1.41.jar'

      java_import 'java.lang.System' do |pkg, cls|
        'JSystem'
      end

      java_import 'java.io.ByteArrayOutputStream' do |pkg, cls|
        'JBAOut'
      end

      java_import 'java.io.PrintStream' do |pkg, cls|
        'JPrintStream'
      end

      java_import 'java.lang.String' do |pkg, cls|
        'JString'
      end

      JSystem.setOut(JPrintStream.new(JBAOut.new)) #This shuts the Zehon software up, or any chatty annoying jar for that matter...
      JSystem.setErr(JPrintStream.new(JBAOut.new)) #This shuts the Zehon software up, or any chatty annoying jar for that matter...

      java_import 'com.zehon.sftp.SFTP' do |pkg, cls|
        'JSFTP'
      end

      unix_box = "vahdrtvapp05.aac.va.gov"
      puts "What host shall we upload SHAMU to?  Hit enter for the default of #{unix_box}"
      input = $stdin.gets.chomp
      unix_box = input unless input.eql?("")
      puts "Enter the login id: "
      login = $stdin.gets.chomp
      hide_password = true
      if (JSystem.console().nil?)
        puts "This script will display the password when run within the IDE.  Please run \"rake utilities:deploy_shamu\" from SHAMU's root directory to avoid this."
        puts "Kill this script if this is not OK."
        hide_password = false
      end
      puts "Enter password: "
      password = (JString.new(JSystem.console().readPassword())).to_s if hide_password
      password = $stdin.gets.chomp unless hide_password
      remote_location = "/tmp"
      puts "Where shall I upload the file?  Hit enter for the default of #{remote_location}:"
      input = $stdin.gets.chomp
      remote_location = input unless input.eql?("")
      success = 1
      print "Attempting to upload file #{file}..."
      comfort_dots
      remote_name = file.split(/\\|\//)[-1]
      status = JSFTP.sendFile(file,remote_location, remote_name, unix_box, login, password)
      comfort_dots(false)
      success = (status == success)
      puts "\nUpload completed succesfully!" if success
      puts "\nUpload failed.  You may need to manually upload #{file}" unless success
    end

  end

  def comfort_dots (comfort = true)
    @comfort = comfort
    if comfort
      dots = Thread.new do
              dot_count = 0
              while @comfort
                print "."
                dot_count += 1
                sleep 5
                puts "" if (dot_count % 20 == 0)
              end
      end
    end
  end

  def setup_environment
    known_env = false
    env_hash = {}
    until known_env
      puts "Are we building a (m) Mongrel based app (Zip file) or (w) Weblogic App (War)? Enter w or m. "
      env1 = $stdin.gets.chomp
      puts "Are we configuring for development (only for weblogic based deployments), test or production (ensure ./config/configure_environment*.txt is configured before responding)?  Enter d, t or p:"
      env2 = $stdin.gets.chomp
      known_env = (env2.eql?('d') || env2.eql?('t') || env2.eql?('p')) and (env1.eql?('m') || env1.eql?('w')) if env1.eql?('w')
      known_env = (env2.eql?('t') || env2.eql?('p')) and (env1.eql?('m') || env1.eql?('w')) if env1.eql?('m')
      env_hash[:deployment] = env2.to_sym
      env_hash[:type] = env1.to_sym
    end

    config_string = Utilities::FileHelper.file_as_string('./config/configure_environment.txt') if (env_hash[:type] == :m)
    config_string = Utilities::FileHelper.file_as_string('./config/configure_environment_war.txt') if (env_hash[:type] == :w)
    config_array = config_string.split("\n")
    config_hash = {}
    file = nil
    file_string = nil
    config_array.each do |line|
      next if line =~ /^\s*#|^\s*$/
      if (line =~ /^\s*FILE:(.+)/)
        file = $1.strip
      else
        config_hash[file] = [] if config_hash[file].nil?
        replacement = line.split('|').map do |e| e.strip end
        if (env_hash[:type].eql?(:w))
          #weblogic
          if (replacement.length == 2)
            replacement << replacement[1] << replacement[1]
          end
          config_hash[file] << [replacement[0],replacement[1]] if (env_hash[:deployment].eql?(:d))
          config_hash[file] << [replacement[0],replacement[2]] if (env_hash[:deployment].eql?(:t))
          config_hash[file] << [replacement[0],replacement[3]] if (env_hash[:deployment].eql?(:p))
        else
          #mongrel
          replacement << replacement[1] if (replacement.length == 2)
          config_hash[file] << [replacement[0],replacement[1]] if (env_hash[:deployment].eql?(:t))
          config_hash[file] << [replacement[0],replacement[2]] if (env_hash[:deployment].eql?(:p))
        end
      end
    end
    config_hash.keys.each do |file|
      #puts "For File #{file}"
      file_string = Utilities::FileHelper.file_as_string(file)
      config_hash[file].each do |replacement|
        #puts "--->#{replacement[0]}<---- ::: ----->#{replacement[1]}<-------"
        file_string.gsub!(replacement[0]){|match| replacement[1]}
      end
      File.chmod 0777, file
      #puts "Modifying file #{file}"
      open(file,'w') do |f| f.puts file_string end
    end
    #this does not work... Why?
    #rake assets:precompile
    #location = `pwd`
    #puts "Running rake assets:precompile in #{location}..."
    #precompile = `rake --trace assets:precompile`
    #puts "done!"
    #puts precompile
    env_hash
  end

  def build_war(env, root_dir, deployment_dir)
    #root_dir is usually c:\temp\SHAMU
    #deployment_dir usually c:\temp\SHAMU\PSTDashboard
    job_jars=Dir["./jobs/**/*.jar"]
    job_jars.each do |jar|
      File.rename(jar,"#{jar}.zip")
    end
    puts "Starting Warbler..."
    system('warble.bat')
    puts "Finished with Warbler!"
    puts "Moving war up a level"
    staging_loc = "#{root_dir}/war_staging"
    war_loc = "#{staging_loc}/PSTDashboard"
    FileUtils.mkdir_p war_loc
    FileUtils.mv("#{deployment_dir}/PSTDashboard.war", war_loc)
    puts "War moved to staging location..."
    Dir.chdir(war_loc)
    puts "Extracting war..."
    system 'jar xvf PSTDashboard.war'
    puts 'Done with jar extraction!'

    job_jars=Dir["./WEB-INF/jobs/**/*.jar.zip"]
    job_jars.each do |jar|
      new_name = jar.chop.chop.chop.chop
      File.rename(jar,new_name)
      puts "Renamed #{jar} to #{new_name}"
    end

    #we need to set gem_home into the WEB-INF/gems directory
    #As we have dependencies on gems that run outside of rails via backticks/system call but within
    #the overall SHAMU application warbler cannot detect this and misses gems...
    lib_jars = Dir["#{deployment_dir}/lib/lib/*.jar"]
    lib_jars.each do |jar|
      FileUtils.cp(jar, './WEB-INF/lib/lib')
    end
    FileUtils.rmtree "./WEB-INF/gems"
    FileUtils.rmtree "./WEB-INF/gem_home"
    FileUtils.cp_r("#{deployment_dir}/gem_home", './WEB-INF/')
    FileUtils.cp_r("#{deployment_dir}/script", './WEB-INF/')
    FileUtils.move('./WEB-INF/gem_home', './WEB-INF/gems')
    FileUtils.rm(war_loc+'/PSTDashboard.war')
    Dir.chdir(staging_loc)
    puts "Rebuilding war in #{staging_loc}..."
    output = `jar cfM PSTDashboard.war PSTDashboard 2>&1`
    puts "#{output}\nDone!"
    puts "Moving #{staging_loc}\\PSTDashboard.war to  #{root_dir}\\PSTDashboard.war"
    FileUtils.mv("#{staging_loc}/PSTDashboard.war", "#{root_dir}/PSTDashboard.war")
    FileUtils.rmtree staging_loc
    Dir.chdir(deployment_dir)
    puts "Done with war!"
  end

end