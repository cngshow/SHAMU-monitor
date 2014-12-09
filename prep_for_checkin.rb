require 'fileutils'
include FileUtils


def prep_for_checkin
  puts "Preparing SHAMU for checkin..."
  puts "Shamu is shutdown right? (enter y for yes)"
  answer =  $stdin.gets
  answer.chomp!
  if (answer.casecmp('y') != 0)
    puts "Please shut SHAMU down and rerun."
    exit 0
  end
  failures = []
  delete_contents('./tmp/*',failures)
  delete_contents('./log/*',failures)
  delete_contents('./public/historical_charts/data/*',failures)
  delete_contents('./public/message_traffic_charts/*',failures)
  delete_contents('./jobs/tasks/message_replay/*.log',failures)
  delete_contents('./jobs/tasks/message_replay/*.hash',failures)
  puts "Moving gem_home up a directory..."
  begin
    FileUtils.mv("./gem_home","../gem_home")
  rescue
  end
  puts failures.join("\n")
  puts "Hit enter when checkin is complete and I will restore gem_home..."
  $stdin.gets
  FileUtils.mv("../gem_home","./gem_home")
end


def delete_contents(location,failures)
  Dir.glob(location).each do |f|
    begin
      if(File.directory?(f))
        FileUtils.remove_dir f
      else
        File.delete f
      end
      puts "Removed #{f}"
    rescue => ex
     failures << "Please manually delete #{f}"
    end
  end
end

prep_for_checkin
