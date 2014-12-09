######Begin addition
require 'java'

java_import 'java.lang.Runtime' do |pkg, cls|
  'JRuntime'
end

java_import 'java.io.OutputStreamWriter' do |pkg, cls|
  'JWrite'
end

java_import 'java.io.BufferedWriter' do |pkg, cls|
  'JBWrite'
end
######End addition

module Mail
  # A delivery method implementation which sends via sendmail.
  #
  # To use this, first find out where the sendmail binary is on your computer,
  # if you are on a mac or unix box, it is usually in /usr/sbin/sendmail, this will
  # be your sendmail location.
  #
  #   Mail.defaults do
  #     delivery_method :sendmail
  #   end
  #
  # Or if your sendmail binary is not at '/usr/sbin/sendmail'
  #
  #   Mail.defaults do
  #     delivery_method :sendmail, :location => '/absolute/path/to/your/sendmail'
  #   end
  #
  # Then just deliver the email as normal:
  #
  #   Mail.deliver do
  #     to 'mikel@test.lindsaar.net'
  #     from 'ada@test.lindsaar.net'
  #     subject 'testing sendmail'
  #     body 'testing sendmail'
  #   end
  #
  # Or by calling deliver on a Mail message
  #
  #   mail = Mail.new do
  #     to 'mikel@test.lindsaar.net'
  #     from 'ada@test.lindsaar.net'
  #     subject 'testing sendmail'
  #     body 'testing sendmail'
  #   end
  #
  #   mail.deliver!
  class Sendmail

    def initialize(values)
      self.settings = { :location       => '/usr/sbin/sendmail',
                        :arguments      => '-i -t' }.merge(values)
    end

    attr_accessor :settings

    def deliver!(mail)
      envelope_from = mail.return_path || mail.sender || mail.from_addrs.first
      return_path = "-f " + '"' + envelope_from.escape_for_shell + '"' if envelope_from

      arguments = [settings[:arguments], return_path].compact.join(" ")

      self.class.call(settings[:location], arguments, mail.destinations.collect(&:escape_for_shell).join(" "), mail)
    end

    #original method below
    #def self.call(path, arguments, destinations, mail)
    #  IO.popen("#{path} #{arguments} #{destinations}", "w+") do |io|
    #    io.puts mail.encoded.to_lf
    #    io.flush
    #  end
    #end

    #new version
    def self.call(path, arguments, destinations, mail)
      process = JRuntime.getRuntime().exec("#{path} #{arguments} #{destinations}")
      outputStream = process.getOutputStream
      writer = JBWrite.new(JWrite.new(outputStream))
      email = mail.encoded.to_lf
      writer.write(email,0,email.length)
      writer.close
    end
  end
end
