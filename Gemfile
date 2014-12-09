source 'http://rubygems.org'

gem 'rails', '3.2.3'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'activerecord-jdbcsqlite3-adapter'
gem 'activerecord-jdbc-adapter'

gem 'jruby-openssl'
gem 'json'
gem 'mongrel'
gem 'gem_plugin'
gem 'devise'
gem 'devise-encryptable'
gem 'orderedhash'
gem 'whenever'
gem 'log4r'
gem 'will_paginate'
gem 'rake'
gem 'rmagick4j'
gem 'hoe'
gem 'gruff'
gem 'warbler'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  #gem 'jquery-datatables-rails', github: 'rweng/jquery-datatables-rails' - see railscasts 340
  #gem 'jquery-ui-rails'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'


# the javascript engine for execjs gem
platforms :jruby do
  group :assets do
    gem 'therubyrhino'
  end
end
