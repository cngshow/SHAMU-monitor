require 'helpers'
require "java"
require "rubygems"
require "./lib/jars/ojdbc6.jar"

class JobMetadata < ActiveRecord::Base
  self.table_name = 'job_metadatas'
	include SystemPropConstants
	has_many :escalations, :dependent => :destroy, :order => 'priority ASC'
	accepts_nested_attributes_for :escalations

	scope :job_code, lambda {|jc| {:conditions => ["job_code = ?", jc] } }
	#validates_associated :escalations  #use this if escalations are moved to a separate page

	validates_length_of       :short_desc,    :within => 0..50
	validates_numericality_of :max_execution_minutes, :integer_only => true, :greater_than_or_equal_to => 0, :message => ' is not an integer value. Please specify the max execution time in minutes.'
	validates_numericality_of :stale_after_min, :integer_only => true, :greater_than_or_equal_to => 0, :message => ' is not an integer value. Please specify the time period beyond which the data becomes stale in minutes.'

	validate :valid_emails?
	validate :valid_escalation?
	validates_presence_of :introscope_job_code, :if => Proc.new{|jmd| jmd.use_introscope_job_code}
	validates_presence_of :introscope_short_desc, :if => Proc.new{|jmd| jmd.use_introscope_short_desc}
	validates_presence_of :introscope_long_desc, :if => Proc.new{|jmd| jmd.use_introscope_long_desc}
  validates_uniqueness_of :job_code

  alias_attribute :desc, :description

	def get_escalation_colors
		colors = []
		used_colors = self.escalations.map {|esc| esc.color_name}
		$application_properties['escalation_colors'].split(';').each do
		|color_name_and_code|
			val = color_name_and_code.split('=>')
			colors << val[0].strip unless used_colors.include?(val[0])
		end
		colors.map{|e| e.upcase}
	end

	#returns an array.  Element 0 is the color_code, element 1 is the priority
	def self.escalation_color_data(lookup_color)
	  $logger.debug "escalation_color_data " << lookup_color
		lookup_color.upcase!
		$application_properties['escalation_colors'].split(';').each do
		|color_data|
			val = color_data.split('=>')
			color = val[0].strip
			color_code, priority = val[1].split(',').map {|e| e.strip}
			priority = priority.to_i
			val[0].strip.eql?(lookup_color)
			$logger.debug "For color " << color << " the color code is " << color_code << " and the priority is " << priority.to_s
			return [color_code, priority] if val[0].strip.upcase.eql?(lookup_color.upcase)
		end
		$logger.debug "returning nil for color #{lookup_color}"
		raise "Illegal color lookup performed on color #{lookup_color}.  Was the runner task tied to ensure_escalations_present run?"
	end

	def get_last_log_entry
		JobLogEntry.find(:last, :conditions => ["job_code = ?", self.job_code])
	end

	def get_last_log_entry_with_status(run_status)
		JobLogEntry.find(:last, :conditions => ["job_code = ? and run_status = ?", self.job_code, run_status])# check references and remove
	end

	def get_last_known_status
		JobLogEntry.get_last_tracked_status(self.job_code, true)
	end

	def JobMetadata.get_last_known_status_for_jc(job_code,run_data)
		jle = JobLogEntry.get_last_tracked_status(job_code, true)
		if (run_data.size == 0)
			result = jle.nil? ? 'GREEN' : jle.status
		else
			result = (jle.nil? || jle.run_data.nil? || jle.run_data.eql?(''))  ? 'NO_DATA' : jle.run_data
			unless (jle.nil?)
				stale = $application_properties['run_data_stale_after_minutes'].to_i
				if (((Time.now - jle.finish_time)/60) >= stale)
					result = 'NO_DATA'
				end
			end
		end
		puts result
    result
	end

	def is_suspended?
		time_suspension = false
		if (self.suspend && self.stop < self.resume)
			now = Time.now
			time_suspension = (self.stop <= now && now <= self.resume)
			if (!time_suspension && self.stop <= now)
				$db_lock.synchronize {
					self.suspend = time_suspension
					self.save(:validate => false)
				}
			end
		end

		return true if ! self.active

		#check to see if the system is suspended via the system_props table
		begin
			suspended = Boolean(SystemProp.get_value(SUSPEND))
			$logger.info "Job " + self.job_code + " was not run due to a system job suspension." if suspended
			return true if suspended
		rescue
			$logger.error "invalid value set on system prop #{SUSPEND}."
		end
		return time_suspension
	end

  def self.repair_escalations
    self.ensure_escalations_present(false)
  end
	#called by a runner task
	def self.ensure_escalations_present(trackable_only = true)
		$application_properties = PropLoader.load_properties('./pst_dashboard.properties')
		jmds = find(:all, :conditions => ["track_status_change = ?", true]) if trackable_only
    jmds = find(:all) unless trackable_only
		jmds.each do
		|jmd|
      #puts jmd.job_code
			colors = jmd.get_escalation_colors
			save_required = false
			escalations = jmd.escalations
			escalation_colors = escalations.map {|esc| esc.color_name}
			new_colors = colors - escalation_colors
			removed_colors = escalation_colors - colors

			removed_colors.each do |color|
				escalations.each do |esc|
					if (color.eql?(esc.color_name))
					 esc.delete
					 save_required = true
					 puts "jmd " + jmd.job_code + " is having the " + color + " escalation removed. "
					 escalations = escalations - [esc]
					end
				end
			end

			escalations.each do #ensure priorities are current
			|esc|
				supposed_priority = escalation_color_data(esc.color_name)[1]
				current_priority = esc.priority
				#puts "#{esc.color_name}  supposed_priority  #{supposed_priority.to_s}"
				#puts "#{esc.color_name}  current_priority  #{current_priority.to_s}"
				if (current_priority != supposed_priority)
					esc.priority = supposed_priority
					puts "jmd " + jmd.job_code + " is having the " + esc.color_name + " priority changed from " + current_priority.to_s + " to " + supposed_priority.to_s
				save_required = true
				end
			end

			new_colors.each do |color|
				priority = escalation_color_data(color)[1]
				new_escalation = Escalation.new
				new_escalation.priority = priority
				new_escalation.color_name = color
				if (color.eql?("RED"))
				new_escalation.end_min = nil
				new_escalation.enabled = true
				else
				new_escalation.end_min = 0
				end

				jmd.escalations << new_escalation
				save_required = true
				puts "jmd " + jmd.job_code + " is having the " + color + " escalation added. "
			#puts "the color code is " << escalation_color_data(color)[0].to_s
			end
			jmd.save(:validate => false) if save_required
		end
	end

	def self.add_escalations(jmd)
		return unless jmd.escalations.empty?
		colors = jmd.get_escalation_colors
		colors.each do |color|
			priority = escalation_color_data(color)[1]
			new_escalation = Escalation.new
			new_escalation.priority = priority
			new_escalation.color_name = color
			new_escalation.end_min = (color.eql?("RED")) ? nil : 0
			new_escalation.enabled = (color.eql?("RED"))
			jmd.escalations << new_escalation
		end
	end

	def self.list_escalations
		jmds = find(:all, :conditions => ["track_status_change = ?", true])
		jmds.each do
		|jmd|
			puts "For JMD " << jmd.job_code << " we have the following escalation IDs:"
			jmd.escalations.sort.each do |esc|
				puts "Escalation " << esc.color_name << " -- DESC -- " << esc.desc.to_s << " -- ID=" << esc.id.to_s
			end
		end
  end

  def self.delete_all
    jmds = JobMetadata.all
    jmds.each do |jmd|
      print "Going to destroy " + jmd.job_code
      jmd.destroy
      puts " -- Done!"
    end
  end

	protected

	def valid_emails?
		emails_ok?(email_cc, "email_cc")
		emails_ok?(email_to, "email_to")
		self.escalations.each do |esc|
			emails_ok?(esc.email_to, "the #{esc.color_name} escalation email_to")
			emails_ok?(esc.email_cc, "the #{esc.color_name} escalation email_cc")
		end
	end


	def valid_escalation?
		end_min = 0
		self.escalations.each do |esc|
			next unless esc.enabled
			next if (esc.color_name.eql?("RED"))
			# $logger.error("esc.color_name=" + esc.color_name.to_s)
			# $logger.error("esc.end_min.to_sym nil? " + esc.end_min.to_sym.nil?.to_s)
			# $logger.error("esc.end_min=" + esc.end_min.to_s)
			if (esc.end_min.nil? or end_min >= esc.end_min)
				errors.add(:the, "#{esc.color_name} escalation has an invalid end minute time.  The end minutes of the escalations must be strictly increasing.")
			end
			end_min = esc.end_min
		end
	end

	private

	def emails_ok?(emails, email_header)
		emails_array = emails.split(/\r\n|\n/)
		return if emails_array.nil?
		emails_array.each do
		|email|
			email.strip!
			next if email.nil?
			if email !~/^(?:[\w._%+-]+@[\w\.-]+\.[A-Za-z]{2,4})$/
				errors.add(email_header," is not a new line delimited list of valid email addresses. Is '#{email}' the address you intended?")
			return
			end
		end
	end
end
