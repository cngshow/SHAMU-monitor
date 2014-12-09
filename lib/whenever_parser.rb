require './lib/prop_loader'

class WheneverParse

  def initialize(whenever_output_string)
    @whenever = whenever_output_string
    begin
      if $application_properties.nil?
        $application_properties = PropLoader.load_properties('./pst_dashboard.properties')
      end
    rescue
      puts "Failed to load ./pst_dashboard.properties "<< $!
      Process.exit
    end
    validate
  end

  def get_schedules_and_commands
    r_val = []
    seen_hash = {} #quartz does not like the same job twice!
    delimiter = $application_properties['whenever_split']
    @w_a.each do |line|
      (schedule, command) = line.split(delimiter)
      unless (command.nil?)
        next if schedule.eql?("@reboot") #ignore reboot requests not supported!
        schedule.strip!
        command.strip!
        schedule = quartz_compatible(schedule)
        command =~ /'(.*)'/
        command = $1 unless $1.nil?
        if seen_hash[schedule+command].nil?
          seen_hash[schedule+command]  = 1
        else
          seen_hash[schedule+command] = seen_hash[schedule+command] + 1
        end
        r_val << [schedule, command] if (seen_hash[schedule+command] == 1)
      end
    end
    r_val
  end

  private

  def validate
    @w_a = @whenever.split(/\n/)
    success_string = $application_properties['whenever_success']
    maybe_successful = @w_a[-2]
    success = success_string.eql?(maybe_successful)
    raise "Scheduling failed!" unless success_string.eql? maybe_successful
  end

  # @param cron_expression [Object]
  def quartz_compatible(cron_expression)
    #quartz supports the second field and cron does not so we must add it in every case
    quartz_expression = "0 " << cron_expression
    #from quartz:
    #Support for specifying both a day-of-week AND a day-of-month parameter is not implemented.
    schedule_parts = quartz_expression.split(/\s+/)
    second = schedule_parts[0]
    minute = schedule_parts[1]
    hour = schedule_parts[2]
    day_of_month = schedule_parts[3]
    month = schedule_parts[4]
    day_of_week = schedule_parts[5]
    day_of_week = (day_of_week.to_i + 1).to_s if (day_of_week =~ /[0-6]/)

    #day_of_month will always take precedence over day_of_week
    if (!day_of_month.eql? '*')
      day_of_week = '?'
    elsif (!day_of_week.eql? '*')
        day_of_month = '?'
    else
      day_of_week = '?'
    end
    second + " " + minute + " " + hour + " " + day_of_month + " " + month + " " + day_of_week
  end

end