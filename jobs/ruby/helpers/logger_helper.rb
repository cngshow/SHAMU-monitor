require 'rubygems'
require 'log4r'
include Log4r

module JobLogging
  def get_logger(logFile, tag, logLevel, trace = false)
    logger = Logger.new(tag)
    pf = PatternFormatter.new(:pattern => "%C: %d %l %m Trace: %t")
    fo = FileOutputter.new("f1", :filename => logFile, :trunc => false, :formatter => pf)
    logger.outputters << fo
    level = logLevel.upcase.to_sym
    logger.level= (level == :DEBUG ? DEBUG :
                  (level == :INFO ? INFO :
                  (level == :WARN ? WARN :
                  (level == :ERROR ? ERROR :
                  (level == :FATAL ? FATAL :
                   UNKNOWN)))))
    logger.trace= trace
    logger
  end
end
