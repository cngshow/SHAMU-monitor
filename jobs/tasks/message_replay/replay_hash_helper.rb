module ReplayHashHelper

  def initialize_replayed_message_hash(hash_trim_days_back)
    if (File.exists?(@replay_check_file))
      @replay_check_hash = Marshal.load(File.read(@replay_check_file))
    else
      @replay_check_hash = Hash.new
    end

    #blow away all data if days back is negative
    if (hash_trim_days_back < 0)
      @replay_check_hash = Hash.new
    elsif (hash_trim_days_back == 0)
      #do nothing - keep the current hash unchanged
    else
      #trim off replayed message data if the days back is greater than zero
      cutoff_time = Time.now.to_i - (hash_trim_days_back*24*60*60)

      @replay_check_hash.delete_if { |k, v|
        return false if k.eql?(:supporting_data)
        v.to_i < cutoff_time
      }
    end
    #$logger.info(@replay_check_hash.inspect)
  end
end
