class TimeUtils  
  
  ZoneOffset = {
      'UTC' => 0,
    # ISO 8601
      'Z' => 0,
    # RFC 822
      'UT' => 0, 'GMT' => 0,
      'EST' => -5, 'EDT' => -4,
      'CST' => -6, 'CDT' => -5,
      'MST' => -7, 'MDT' => -6,
      'PST' => -8, 'PDT' => -7,
    # Following definition of military zones is original one.
    # See RFC 1123 and RFC 2822 for the error in RFC 822.
      'A' => +1, 'B' => +2, 'C' => +3, 'D' => +4,  'E' => +5,  'F' => +6, 
      'G' => +7, 'H' => +8, 'I' => +9, 'K' => +10, 'L' => +11, 'M' => +12,
      'N' => -1, 'O' => -2, 'P' => -3, 'Q' => -4,  'R' => -5,  'S' => -6, 
      'T' => -7, 'U' => -8, 'V' => -9, 'W' => -10, 'X' => -11, 'Y' => -12,
  }
  
  def self.offset_to_zone(offset)
    return 'UTC' if offset.nil?
    is_dst = Time.now.dst?
    offset = offset.to_i
    ZoneOffset.each_pair do |time_zone, zone_offset| 
      return time_zone if ((zone_offset == offset) && ((time_zone.match('D') && is_dst) || (!time_zone.match('D') && !is_dst))) 
    end
    return 'UTC' #default to UTC if we cannot figure it out
    #raise ArgumentError, "Illegal arguments!  The offset " << offset.to_s << " is unknown."
  end
  
    def self.zone_abbreviation(time)
    return 'UTC' if time.nil?
    is_dst = time.dst?
    offset = time.utc_offset/(60*60)
    ZoneOffset.each_pair do |time_zone, zone_offset| 
      return time_zone if ((zone_offset == offset) && ((time_zone.match('D') && is_dst) || (!time_zone.match('D') && !is_dst))) 
    end
    return 'UTC' #default to UTC if we cannot figure it out
    #raise ArgumentError, "Illegal arguments!  The offset " << offset.to_s << " is unknown."
  end
end