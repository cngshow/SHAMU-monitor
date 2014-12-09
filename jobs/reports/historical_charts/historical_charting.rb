#!/u01/dev/ruby_1.8.7/bin/ruby
require 'time'

class Historical_Charting
  def self.transform_data(file, output)
    #declare a file handle for writing the epoch time into the current run file
    file_handle = File.open(output,"w")
    
    File.open(file, 'r') do |data_file|
      data_file.read.each_line do |line|
        line.chomp!
        
        #data lines begin with the datetime formatted as yyyymmddhh24mi (201104200005 as 12:05AM on 04/20/2011)
        if (line =~ /\d{12}.*/)
          data = line.split(',')
          dt = data.shift

          #pull out the date and time components and compute the epoch time
          epoch = Time.parse(dt).to_i.to_s
          
          #write out the data line
          new_line = epoch << ',' << data.join(',')
          file_handle.puts new_line
        end
      end
    end
      
    #close the data file if one was opened
    file_handle.close unless file_handle.nil?
  end
end

#transform the data writing the to a new file in a dated directory based on the data in the file
Historical_Charting.transform_data(ARGV[0],ARGV[1])
