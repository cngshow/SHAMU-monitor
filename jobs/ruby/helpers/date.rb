#!/u01/dev/ruby_1.8.7/bin/ruby
days_back = ARGV[0].to_i
time = Time.now.to_i - days_back*24*60*60
time = Time.at(time)
year = time.year.to_s
month = time.strftime('%m')
day = time.strftime('%d')
puts year+month+day