#!/u01/dev/ruby_1.8.7/bin/ruby
require 'rubygems'
require 'gruff'
require 'orderedhash'
require 'ftools'


class MessageGraphing
  
  public 
    @@date = nil
  
  private 
    @@data_hash = OrderedHash.new
    @@outage_hash = OrderedHash.new
    @@missing_data = [0,0,0,0,0,0,0,0,0,0,0,0]
    @@hours = (0..23).to_a
    @@graph_hash = {}
    @@theme_overlay = {:colors => %w(red blue),:marker_color => 'black',:background_colors => %w(cornsilk white)}
    @@theme_odd = {:colors => %w(red),:marker_color => 'black',:background_colors => %w(cornsilk white)}
    @@theme_even = {:colors => %w(blue),:marker_color => 'black',:background_colors => %w(cornsilk white)}
    @@data_below = false
  
  def self.load_data(file)
    File.open(file, 'r') do |data_file|
      data_file.read.each_line do |line|
        @@data_below = true if (line.chomp.eql?("DATA_BELOW"))
        @@data_below = false if (line.chomp.eql?("DATA_ABOVE"))
        next if (line.chomp.eql?("DATA_BELOW"))
        next unless @@data_below
        data_array = line.split(',')  
        date = data_array.shift
        date = date.split('.')
        hour = date[1].to_i
        date = date[0]
        @@date = date
        @@data_hash[date] = OrderedHash.new if @@data_hash[date].nil?
        aaaa = @@data_hash
        @@data_hash[date][hour] = OrderedHash.new if @@data_hash[date][hour].nil?
        message_type = data_array.shift
        @@data_hash[date][hour][message_type] = OrderedHash.new if @@data_hash[date][hour][message_type].nil?
        sending_app = data_array.shift
        @@data_hash[date][hour][message_type][sending_app] = OrderedHash.new if @@data_hash[date][hour][message_type][sending_app].nil?
        @@data_hash[date][hour][message_type][sending_app] = data_array
      end
    end
  end
  
  def self.prepare_data_for_graphing()
    @@data_hash.each_key do |date|
      #if there is an outage longer than 24 hours, the data file will
      #contain the date and the string 'NO_DATA'
      #if this is encountered, set flag, keep the date and proceed to graphing
      if @@data_hash[date][0].to_s.strip.eql?('NO_DATA')
        $no_data = true
        @@graph_hash = @@data_hash
        return
      end
      next if @@data_hash[date].nil?
      va_z01_array = []
      va_z02_array = []
      va_z03_array = []
      va_z04_array = []
      va_z05_array = []
      va_z06_array = []
      va_z07_array = []
      va_a24_array = []
      dod_z01_array = []
      dod_z02_array = []
      dod_z03_array = []
      dod_z04_array = []
      dod_z05_array = []
      dod_z06_array = []
      dod_z07_array = []
      mpi_a24_ack_array = []
      va_total_array = []
      dod_total_array = []
      @@hours.each do |hour|
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['TOTAL'].nil? && !@@data_hash[date][hour]['TOTAL']['VA'].nil?)
          va_total_array << @@data_hash[date][hour]['TOTAL']['VA'].map! do |element| element.to_i end 
        else
          va_total_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['TOTAL'].nil? && !@@data_hash[date][hour]['TOTAL']['DOD'].nil?)
          dod_total_array << @@data_hash[date][hour]['TOTAL']['DOD'].map! do |element| element.to_i end 
        else
          dod_total_array << @@missing_data
        end # end unless        
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z01'].nil? && !@@data_hash[date][hour]['Z01']['VA'].nil?)
          va_z01_array << @@data_hash[date][hour]['Z01']['VA'].map! do |element| element.to_i end 
        else
          va_z01_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z02'].nil? && !@@data_hash[date][hour]['Z02']['VA'].nil?)
          va_z02_array << @@data_hash[date][hour]['Z02']['VA'].map! do |element| element.to_i end 
        else
          va_z02_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z03'].nil? && !@@data_hash[date][hour]['Z03']['VA'].nil?)
          va_z03_array << @@data_hash[date][hour]['Z03']['VA'].map! do |element| element.to_i end 
        else
          va_z03_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z04'].nil? && !@@data_hash[date][hour]['Z04']['VA'].nil?)
          va_z04_array << @@data_hash[date][hour]['Z04']['VA'].map! do |element| element.to_i end 
        else
          va_z04_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z05'].nil? && !@@data_hash[date][hour]['Z05']['VA'].nil?)
          va_z05_array << @@data_hash[date][hour]['Z05']['VA'].map! do |element| element.to_i end 
        else
          va_z05_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z06'].nil? && !@@data_hash[date][hour]['Z06']['VA'].nil?)
          va_z06_array << @@data_hash[date][hour]['Z06']['VA'].map! do |element| element.to_i end 
        else
          va_z06_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z07'].nil? && !@@data_hash[date][hour]['Z07']['VA'].nil?)
          va_z07_array << @@data_hash[date][hour]['Z07']['VA'].map! do |element| element.to_i end 
        else
          va_z07_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['ADT_A24'].nil? && !@@data_hash[date][hour]['ADT_A24']['VA'].nil?)
          va_a24_array << @@data_hash[date][hour]['ADT_A24']['VA'].map! do |element| element.to_i end 
        else
          va_a24_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['ACK_A24'].nil? && !@@data_hash[date][hour]['ACK_A24']['MPI'].nil?)
          mpi_a24_ack_array << @@data_hash[date][hour]['ACK_A24']['MPI'].map! do |element| element.to_i end 
        else
          mpi_a24_ack_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z01'].nil? && !@@data_hash[date][hour]['Z01']['DOD'].nil?)
          dod_z01_array << @@data_hash[date][hour]['Z01']['DOD'].map! do |element| element.to_i end 
        else
          dod_z01_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z02'].nil? && !@@data_hash[date][hour]['Z02']['DOD'].nil?)
          dod_z02_array << @@data_hash[date][hour]['Z02']['DOD'].map! do |element| element.to_i end 
        else
          dod_z02_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z03'].nil? && !@@data_hash[date][hour]['Z03']['DOD'].nil?)
          dod_z03_array << @@data_hash[date][hour]['Z03']['DOD'].map! do |element| element.to_i end 
        else
          dod_z03_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z04'].nil? && !@@data_hash[date][hour]['Z04']['DOD'].nil?)
          dod_z04_array << @@data_hash[date][hour]['Z04']['DOD'].map! do |element| element.to_i end 
        else
          dod_z04_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z05'].nil? && !@@data_hash[date][hour]['Z05']['DOD'].nil?)
          dod_z05_array << @@data_hash[date][hour]['Z05']['DOD'].map! do |element| element.to_i end 
        else
          dod_z05_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z06'].nil? && !@@data_hash[date][hour]['Z06']['DOD'].nil?)
          dod_z06_array << @@data_hash[date][hour]['Z06']['DOD'].map! do |element| element.to_i end 
        else
          dod_z06_array << @@missing_data
        end # end unless
        if (!@@data_hash[date][hour].nil? && !@@data_hash[date][hour]['Z07'].nil? && !@@data_hash[date][hour]['Z07']['DOD'].nil?)
          dod_z07_array << @@data_hash[date][hour]['Z07']['DOD'].map! do |element| element.to_i end 
        else
          dod_z07_array << @@missing_data
        end # end unless
      end # end hours
      @@graph_hash[date] = OrderedHash.new if @@graph_hash[date].nil?
      @@graph_hash[date]['VA_Z01_SENT'] = va_z01_array.flatten
      @@graph_hash[date]['VA_Z02_RESP'] = va_z02_array.flatten
      @@graph_hash[date]['VA_Z03_SENT'] = va_z03_array.flatten
      @@graph_hash[date]['VA_Z04_RESP'] = va_z04_array.flatten
      @@graph_hash[date]['VA_Z05_SENT'] = va_z05_array.flatten
      @@graph_hash[date]['VA_Z06_RESP'] = va_z06_array.flatten
      @@graph_hash[date]['VA_Z06_SENT'] = va_z06_array.flatten
      @@graph_hash[date]['VA_Z07_RESP'] = va_z07_array.flatten
      @@graph_hash[date]['VA_A24_SENT'] = va_a24_array.flatten
      @@graph_hash[date]['MPI_A24_ACK_RESP'] = mpi_a24_ack_array.flatten
      @@graph_hash[date]['DOD_Z01_SENT'] = dod_z01_array.flatten
      @@graph_hash[date]['DOD_Z02_RESP'] = dod_z02_array.flatten
      @@graph_hash[date]['DOD_Z03_SENT'] = dod_z03_array.flatten
      @@graph_hash[date]['DOD_Z04_RESP'] = dod_z04_array.flatten
      @@graph_hash[date]['DOD_Z05_SENT'] = dod_z05_array.flatten
      @@graph_hash[date]['DOD_Z06_RESP'] = dod_z06_array.flatten
      @@graph_hash[date]['DOD_Z06_SENT'] = dod_z06_array.flatten
      @@graph_hash[date]['DOD_Z07_RESP'] = dod_z07_array.flatten
      @@graph_hash[date]['VA_TOTAL_Z_SENT'] = va_total_array.flatten
      @@graph_hash[date]['DOD_TOTAL_Z_RESP'] = dod_total_array.flatten            
    end #end data_hash
  end
  
  def self.draw_graphs(size,file_end,file_location)
    #if no data, skip drawing graphs
    Dir::mkdir(file_location + "#{@@date}") unless FileTest::directory?(file_location + "#{@@date}")
    Dir::mkdir(file_location + "#{@@date}/charts") unless FileTest::directory?(file_location + "#{@@date}/charts")
    unless $no_data
      aaaa = @@graph_hash
      @@graph_hash.each_key do |date|
        begin
        title_date = self.format_date(date)
        @@graph_hash[date].each_key do |graph_type|
          the_graph = Gruff::Line.new(size)
          the_graph.theme = self.get_theme(graph_type)
          $title = "#{graph_type}"
          the_graph.title = "#{title_date} -- " + $title.sub(/_(SENT|RESP)/,'')
          the_graph.labels = MessageGraphing.label_hash(24,12)
          the_graph.data(graph_type,@@graph_hash[date][graph_type])
          the_graph.write("#{file_location}#{@@date}/charts/#{graph_type}#{file_end}.gif")
         end
       rescue => ex
         puts ex.to_s
        end
      end
      date = self.format_date(@@date)
      va_z03_z04_graph = Gruff::Line.new(size)
      va_z03_z04_graph.theme = @@theme_overlay
      va_z03_z04_graph.title = "#{date} -- VA Z03 / DoD Z04"
      va_z03_z04_graph.data('VA Z03s',@@graph_hash[@@date]['VA_Z03_SENT'])
      va_z03_z04_graph.data('DOD Z04s',@@graph_hash[@@date]['DOD_Z04_RESP'])
      va_z03_z04_graph.labels = MessageGraphing.label_hash(24,12)
      va_z03_z04_graph.write("#{file_location}#{@@date}/charts/VA_Z03_Z04#{file_end}.gif")
      
      dod_z03_z04_graph = Gruff::Line.new(size)
      dod_z03_z04_graph.title = "#{date} -- DoD Z03 / VA Z04"
      dod_z03_z04_graph.theme = @@theme_overlay
      dod_z03_z04_graph.data('DOD Z03s',@@graph_hash[@@date]['DOD_Z03_SENT'])
      dod_z03_z04_graph.data('VA Z04s',@@graph_hash[@@date]['VA_Z04_RESP'])
      dod_z03_z04_graph.labels = MessageGraphing.label_hash(24,12)
      dod_z03_z04_graph.write("#{file_location}#{@@date}/charts/DOD_Z03_Z04#{file_end}.gif")
      
      dod_z01_z02_graph = Gruff::Line.new(size)
      dod_z01_z02_graph.title = "#{date} -- DoD Z01 / VA Z02"
      dod_z01_z02_graph.theme = @@theme_overlay
      dod_z01_z02_graph.data('DOD Z01s',@@graph_hash[@@date]['DOD_Z01_SENT'])
      dod_z01_z02_graph.data('VA Z02s',@@graph_hash[@@date]['VA_Z02_RESP'])
      dod_z01_z02_graph.labels = MessageGraphing.label_hash(24,12)
      dod_z01_z02_graph.write("#{file_location}#{@@date}/charts/DOD_Z01_Z02#{file_end}.gif")
      
      va_z01_z02_graph = Gruff::Line.new(size)
      va_z01_z02_graph.theme = @@theme_overlay
      va_z01_z02_graph.title = "#{date} -- VA Z01 / DoD Z02"
      va_z01_z02_graph.data('VA Z01s',@@graph_hash[@@date]['VA_Z01_SENT'])
      va_z01_z02_graph.data('DOD Z02s',@@graph_hash[@@date]['DOD_Z02_RESP'])
      va_z01_z02_graph.labels = MessageGraphing.label_hash(24,12)
      va_z01_z02_graph.write("#{file_location}#{@@date}/charts/VA_Z01_Z02#{file_end}.gif")
      
      dod_z05_z06_graph = Gruff::Line.new(size)
      dod_z05_z06_graph.title = "#{date} -- DoD Z05 / VA Z06"
      dod_z05_z06_graph.theme = @@theme_overlay
      dod_z05_z06_graph.data('DOD Z05s',@@graph_hash[@@date]['DOD_Z05_SENT'])
      dod_z05_z06_graph.data('VA Z06s',@@graph_hash[@@date]['VA_Z06_RESP'])
      dod_z05_z06_graph.labels = MessageGraphing.label_hash(24,12)
      dod_z05_z06_graph.write("#{file_location}#{@@date}/charts/DOD_Z05_Z06#{file_end}.gif")
      
      va_z05_z06_graph = Gruff::Line.new(size)
      va_z05_z06_graph.theme = @@theme_overlay
      va_z05_z06_graph.title = "#{date} -- VA Z05 / DoD Z06"
      va_z05_z06_graph.data('VA Z05s',@@graph_hash[@@date]['VA_Z05_SENT'])
      va_z05_z06_graph.data('DOD Z06s',@@graph_hash[@@date]['DOD_Z06_RESP'])
      va_z05_z06_graph.labels = MessageGraphing.label_hash(24,12)
      va_z05_z06_graph.write("#{file_location}#{@@date}/charts/VA_Z05_Z06#{file_end}.gif")
      
      dod_z06_z07_graph = Gruff::Line.new(size)
      dod_z06_z07_graph.theme = @@theme_overlay
      dod_z06_z07_graph.title = "#{date} -- DoD Z06 / VA Z07"
      dod_z06_z07_graph.data('DOD Z06s',@@graph_hash[@@date]['DOD_Z06_SENT'])
      dod_z06_z07_graph.data('VA Z07s',@@graph_hash[@@date]['VA_Z07_RESP'])
      dod_z06_z07_graph.labels = MessageGraphing.label_hash(24,12)
      dod_z06_z07_graph.write("#{file_location}#{@@date}/charts/DOD_Z06_Z07#{file_end}.gif")
      
      va_z06_z07_graph = Gruff::Line.new(size)
      va_z06_z07_graph.theme = @@theme_overlay
      va_z06_z07_graph.title = "#{date} -- VA Z06 / DoD Z07"
      va_z06_z07_graph.data('VA Z06s',@@graph_hash[@@date]['VA_Z06_SENT'])
      va_z06_z07_graph.data('DoD Z07s',@@graph_hash[@@date]['DOD_Z07_RESP'])
      va_z06_z07_graph.labels = MessageGraphing.label_hash(24,12)
      va_z06_z07_graph.write("#{file_location}#{@@date}/charts/VA_Z06_Z07#{file_end}.gif")
      
      va_a24_a24_ack_graph = Gruff::Line.new(size)
      va_a24_a24_ack_graph.theme = @@theme_overlay
      va_a24_a24_ack_graph.title = "#{date} -- VA A24 / MPI A24_ACK"
      va_a24_a24_ack_graph.data('VA A24s',@@graph_hash[@@date]['VA_A24_SENT'])
      va_a24_a24_ack_graph.data('MPI A24_ACKs',@@graph_hash[@@date]['MPI_A24_ACK_RESP'])
      va_a24_a24_ack_graph.labels = MessageGraphing.label_hash(24,12)
      va_a24_a24_ack_graph.write("#{file_location}#{@@date}/charts/VA_A24_A24_ACK#{file_end}.gif")
  
#      va_a24_a24_ack_graph = Gruff::Line.new(size)
#      va_a24_a24_ack_graph.theme = @@theme_overlay
#      va_a24_a24_ack_graph.title = "#{date} -- VA A24 / MPI A24_ACK"
#      va_a24_a24_ack_graph.data('VA A24s',@@graph_hash[@@date]['VA_A24_SENT'])
#      va_a24_a24_ack_graph.data('MPI A24_ACKs',@@graph_hash[@@date]['MPI_A24_ACK_RESP'])
#      va_a24_a24_ack_graph.labels = MessageGraphing.label_hash(24,12)
#      va_a24_a24_ack_graph.write("#{file_location}#{@@date}/charts/VA_A24_MPI_ACK#{file_end}.gif")
      
      total_overlay_graph = Gruff::Line.new(size)
      total_overlay_graph.theme = @@theme_overlay
      total_overlay_graph.title = "#{date} -- VA / DoD Totals"
      total_overlay_graph.data('VA Total Z\'s',@@graph_hash[@@date]['VA_TOTAL_Z_SENT'])
      total_overlay_graph.data('DOD Total Z\'s',@@graph_hash[@@date]['DOD_TOTAL_Z_RESP'])
      total_overlay_graph.labels = MessageGraphing.label_hash(24,12)
      total_overlay_graph.write("#{file_location}#{@@date}/charts/TOTAL_Z_OVERLAY#{file_end}.gif")
    end    
  end
  
  def self.populate_outages()
     #if no data, keep passing on the date (now contained in @@graph_hash)
     if $no_data
      @@outage_hash = OrderedHash.new
      @@outage_hash = @@graph_hash
    end
    unless $no_data
      @@graph_hash.each_key do |date_string|
        @@graph_hash[date_string].each_key do |graph_type_string|
          data_array = @@graph_hash[date_string][graph_type_string]
          @@outage_hash[date_string] = OrderedHash.new if @@outage_hash[date_string].nil?
          @@outage_hash[date_string][graph_type_string] = OrderedHash.new if @@outage_hash[date_string][graph_type_string].nil?
          #data_array is an array with Z counts in five minute periods from midnight to midnight.  So it will be an array
          # of size 12*1*24 = 288 as there are 12 five minute periods per hour.  We must find the contiguous zeroes, with start and end locations for
          #outage reporting.  Each element of the Array built for @@outage_hash[date_string][graph_type_string] will be a two tuple (Array itself)
          #containing the start of a found zero and the last position of the set of contiguous zeroes.
          two_tuple = Array.new(2)
          last_position = data_array.length-1
           (0..last_position).each do |position|
            if (position == last_position)
              if (data_array[position] == 0)
                two_tuple[1] = position 
                two_tuple[0] = position if two_tuple[0].nil?
                time_data = self.two_tuple_to_time_string(two_tuple)
                @@outage_hash[date_string][graph_type_string][time_data[0]] = Array.new if @@outage_hash[date_string][graph_type_string][time_data[0]].nil?
                @@outage_hash[date_string][graph_type_string][time_data[0]] << time_data[1]
              end
            else#somewhere in the middle
              two_tuple[0] = position if (two_tuple[0].nil? && (data_array[position] == 0))
              if (!two_tuple[0].nil? && (data_array[position + 1] != 0))
                two_tuple[1] = position
                time_data = self.two_tuple_to_time_string(two_tuple)
                aaa =@@outage_hash
                @@outage_hash[date_string][graph_type_string][time_data[0]] = Array.new if @@outage_hash[date_string][graph_type_string][time_data[0]].nil?
                @@outage_hash[date_string][graph_type_string][time_data[0]] << time_data[1]
                two_tuple = Array.new(2)
              end
            end
          end                               
        end
      end
    end
  end
  
  def self.print_outages
    
    va_outages = ['VA_TOTAL_Z_SENT','VA_Z01_SENT','VA_Z02_RESP','VA_Z03_SENT','VA_Z04_RESP','VA_Z05_SENT','VA_Z06_RESP', 'VA_Z07_RESP', 'VA_A24_SENT', 'MPI_A24_ACK_RESP']
    dod_outages = ['DOD_TOTAL_Z_RESP','DOD_Z01_SENT','DOD_Z02_RESP','DOD_Z03_SENT','DOD_Z04_RESP','DOD_Z05_SENT','DOD_Z06_RESP', 'DOD_Z07_RESP']
    iter_array = [va_outages, dod_outages]
    
    @@outage_hash.each_key do |date|
      puts '<html><head><meta content="text/html; charset=ISO-8859-1" http-equiv="content-type">'
      puts "<title>Charts for #{format_date(date)}</title>"
      puts "<style>.odd {background-color:transparent} .even {background-color: #eee} th {background-color: navy; color:white} table {font-size: 10pt} body {font-family: Sans Serif; font-size: 12pt} tr.VA { background-color: #A0CFEC} tr.DoD {background-color: #C6DEFF} .sending_app {font-size: 250%}</style>"
      puts "</head><body>"
      puts "<p>The following table lists the periods of no message flow broken down by sending agency and by Z-message type including a column across all message types. The outage lengths are sorted from largest to smallest with the bullets noting the time period of the outage.<br><br>"
      #if no data, don't write the the hyperlinks
      unless $no_data
        puts "<a href=\"#{$chart_url.to_s}\">Click this link to view the supporting charts illustrating the message traffic for #{format_date(date)}.</a>"
      end
      puts "<br><br></p>"
      puts "<table width=\"100%\" ><tr>"
      puts "<th>Sending Agency</th>"
      puts "<th>Total</th>"
      puts "<th>Z01</th>"
      puts "<th>Z02</th>"
      puts "<th>Z03</th>"
      puts "<th>Z04</th>"
      puts "<th>Z05</th>"
      puts "<th>Z06</th>"
      puts "<th>Z07</th>"
      puts "<th>A24</th>"
      puts "<th>A24_ACK</th>"
      puts "</tr>"
      #if no data, write message
      if $no_data
	puts '<tr><td colspan="11" width="100%">'
	puts '<b>No data returned over the past 24 hours</b><br>'
	puts 'VA CHDR or one of it\'s dependent systems may be experiencing an outage.<br>'
	puts 'Please contact VA-AITC Service Desk for further assistance.'
	puts '</td></tr>'
      
      #otherwise write data
      else 
        iter_array.each do |row|
          agency = Regexp.compile('DOD').match(row[0]) ? 'DoD' : 'VA'
          puts "<tr class=\"#{agency}\"><td valign=\"top\" class=\"sending_app\">"
          puts "<b>#{agency}</b>"
          puts "</td>"
          
           (0..(row.length-1)).each do |row_index|
            graph_type = row[row_index]
            col_style = (row_index % 2) > 0 ? "odd" : "even"
            
            puts "<td valign=\"top\" class=\"#{col_style}\">"
            data = @@outage_hash[date][graph_type]
            outage_found = false
            data.keys.sort.reverse.each do |outage_length|
              next if outage_length < $min_outage.to_i 
              outage_found = true
              puts "<b><u>#{outage_length} Minute</b></u><br>"
              data[outage_length].each do |time|
                puts "<li>#{time}</li><br>"
              end
            end
            puts "<b>No Outages Greater Than #{$min_outage} Minutes</b>" unless outage_found
            puts "</td>"
          end
          puts "</tr>"
        end      
      end
    end
    puts "</table></body></html>"
  end
  
  public 
  @@date = nil
  
  private 
  
  @@data_hash = OrderedHash.new
  @@outage_hash = OrderedHash.new
  @@missing_data = [0,0,0,0,0,0,0,0,0,0,0,0]
  @@hours = (0..23).to_a
  @@graph_hash = {}
  @@theme_overlay = {:colors => %w(red blue),:marker_color => 'black',:background_colors => %w(cornsilk white)}
  @@theme_odd = {:colors => %w(red),:marker_color => 'black',:background_colors => %w(cornsilk white)}
  @@theme_even = {:colors => %w(blue),:marker_color => 'black',:background_colors => %w(cornsilk white)}
  $no_data = nil
  
  def self.label_hash(num_hours,parts_per_hour)
    hash = {}
    labels = (1...num_hours).to_a
    labels.each do |hour|
      hash[hour*parts_per_hour] = "#{hour}"
    end
    hash
  end
  
  def self.format_date(date)
    match = /(\d{4})(\d{2})(\d{2})/.match(date)
    match[2] + '-' + match[3] + '-' + match[1]
  end
  
  def self.two_tuple_to_time_string(two_tuple)
    two_tuple[1] = two_tuple[1] + 1
    start_min = (two_tuple[0]%12)*5
    end_min = (two_tuple[1]%12)*5
    start_min = '0' + start_min.to_s if start_min < 10
    end_min = '0' + end_min.to_s if end_min < 10
    time = (two_tuple[0]/12).to_s+':'+ start_min.to_s + ' - ' + (two_tuple[1]/12).to_s + ':' + end_min.to_s
    time_length = (two_tuple[1] - two_tuple[0])*5
    [time_length,time]
  end
  
  def self.get_date
    @@date
  end
  
  def self.get_theme(graph_type)
    return @@theme_even if Regexp.compile('RESP').match(graph_type)
#    return @@theme_even if Regexp.compile('2|4|6|DOD_TOTAL').match(graph_type)
    @@theme_odd
  end
  
end
$no_data = false
$min_outage = ARGV[2]
$chart_url = ARGV[3]
$root_dir =ARGV[1] + "/message_traffic_charts/"
Dir::mkdir($root_dir) unless FileTest::directory?($root_dir)
MessageGraphing.load_data(ARGV[0])
MessageGraphing.prepare_data_for_graphing
MessageGraphing.draw_graphs('1024x768','',$root_dir)
MessageGraphing.draw_graphs('300x200','_small',$root_dir)
$chart_url = $chart_url.gsub('CURRENT_DATE',MessageGraphing.get_date)
MessageGraphing.populate_outages
MessageGraphing.print_outages
date = MessageGraphing.get_date
File.copy(ARGV[4], "#{$root_dir}#{date}/") unless $no_data
