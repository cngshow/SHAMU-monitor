namespace :users do

  task :default => 'users:admin_all'

  desc "Make all users an administrator"
  task :admin_all => :environment do
    print "About to enable everyone..."
    User.mark_all_as_admin
    puts "Done!"
  end


  desc "Mock up some test users"
  task :create_test_users => :environment do
    puts "About to create test users..."
    ["bob","sally","fred","sarah","sam","billy"].each do |user|
      u = User.new
      u.username = user
      u.email = user + "@someplace.com"
      u.administrator= !(user =~ /^s.*/).nil?
      u.password= "testtest"
      success = u.save!
      puts "User #{user} saved? " << success.to_s
    end
    puts "Done!"
  end


end

