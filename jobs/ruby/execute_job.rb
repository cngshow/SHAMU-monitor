require "./jobs/ruby/lib/job.rb"

job = ARGV[0]
job.chomp!
success = JobExecutor.execute_job(job)

puts "Executed job #{job}!"  if success
puts "Job #{job} Failed to execute!" unless success