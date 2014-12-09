module Utilities
  
  module FileHelper
    def FileHelper.file_as_string(file)
      rVal = ''
      File.open(file, 'r') do |file_handle|
        file_handle.read.each_line do |line|
          rVal << line
        end
      end
      rVal
    end
  end
end