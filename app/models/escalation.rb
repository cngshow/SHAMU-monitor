class Escalation < ActiveRecord::Base
	#	include Comparable
	belongs_to :job_metadata
	#	default_scope :order => 'priority asc'

	scope :job_metadata_id, lambda {|id| {:conditions => ['job_metadata_id = ?', id], :order => 'priority asc'} }

	validates_numericality_of :end_min, :integer_only => true, :allow_nil => true, :greater_than_or_equal_to => 0, :message => "is not an integer value. Please specify the time in minutes."
	#below validations moved to JobMetadata
	#validate :valid_emails_escalation?
	#validate :valid_escalation?
	
	def valid_emails_escalation?()		
		valid_emails?(email_to, "the #{color_name} escalation email_to")
		valid_emails?(email_cc, "the #{color_name} escalation email_cc")
	end

	def valid_escalation?
		end_min = 0
		peers = get_peer_escalations
		for i in (1..(peers.length-1))
			esc_prev = peers[i-1]
			esc = peers[i]
			next unless esc.enabled
			next if (esc.color_name.eql?("RED"))
			if (self.eql?(esc))
				if (end_min.nil? or end_min <= esc_prev.end_min)
					errors.add(:the, "#{esc_prev.color_name} = #{esc_prev.end_min.to_s}  || #{color_name} = #{end_min.to_s} escalation has an invalid end minute time.  The end minutes of the escalations must be strictly increasing.")
				return
				end
			end
		end
	end
	
	def to_s
	  "Escalation color is " + color_name
	end
	
 def get_escalation_based_emails
   peers = get_peer_escalations
   email_to = []
   email_cc = []
   peers.each do |esc|
     to_array = esc.email_to.to_s.split().uniq
     cc_array = esc.email_cc.to_s.split().uniq
     email_to = email_to | to_array
     email_cc = email_cc | cc_array
     return [email_to, email_cc] if self.eql?(esc)
   end
   $logger.error("Reaching this line should be impossible.  Check Escalations.get_escalation_based_emails")
   [email_to, email_cc]
 end
  

	private
	
	def get_peer_escalations
		Escalation.job_metadata_id(self.job_metadata_id).delete_if {|esc| !esc.enabled}
	end

	def valid_emails?(emails, email_header)
		emails_array = emails.split(/\r\n|\n/)
		return if emails_array.nil?
		emails_array.each do
		|email|
			email.strip!
			next if email.nil?
			if email !~/^(?:[\w._%+-]+@[\w\.-]+\.[A-Za-z]{2,4})$/
				errors.add(email_header," is not a new line delimited list of valid email addresses.")
			return
			end
		end
	end

=begin
def <=> (partner)
return 0 if (priority.nil? and partner.priority.nil?)
return 1 if (priority.nil?)
return -1 if (partner.priority.nil?)
return -1 if (priority < partner.priority)
return 1  if (priority > partner.priority)
return 0 #if (end_min == partner.end_min)
end
=end
end