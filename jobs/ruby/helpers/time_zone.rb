timezone = ARGV[0]
offset = ARGV[1] unless ARGV[1].nil?
epoch = ARGV[2] unless ARGV[2].nil?

time = epoch.nil? ? Time.now : Time.at(epoch.to_i)