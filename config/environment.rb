# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
PSTDashboard::Application.initialize!

#require "smtp_tls"

ActionMailer::Base.raise_delivery_errors = true
#ActionMailer::Base.delivery_method = :sendmail
ActionMailer::Base.delivery_method = :smtp
#ActionMailer::Base.smtp_settings = {
#:address => "10.238.10.254",
#:port => 25,
#:domain => 'va.gov' #,
#:user_name => 'shamuveteran',
#:password => 'shamuveteran',
#:authentication => 'plain',
#:enable_starttls_auto => true
#}

=begin
#ActionMailer::Base.default_charset = "utf-8"
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
:address => "smtp.bizmail.yahoo.com",
:port => 587,
:domain => "shamu.va.gov",
:user_name => "shamuveteran",
:password => "shamuveteran123" ,
:enable_starttls_auto => true,
:authentication => :plain
}
=end
