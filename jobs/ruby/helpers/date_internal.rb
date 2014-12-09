days_back = ARGV[0].to_i
retval = ARGV[1]
retval = "yyyymmdd" if retval.nil?
time = Time.now.to_i - days_back*24*60*60
time = Time.at(time)
year = time.year.to_s
month = time.strftime('%m')
day = time.strftime('%d')
hour = time.strftime('%H')
minute = time.strftime('%M')
second = time.strftime('%S')
retval.gsub!("yyyy",year)
retval.gsub!("mm",month)
retval.gsub!("dd",day)
retval.gsub!("hh",hour)
retval.gsub!("mi",minute)
retval.gsub!("ss",second)
retval
