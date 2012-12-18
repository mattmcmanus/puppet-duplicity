source :rubygems

if ENV.key?('PUPPET_VERSION')
    puppetversion = "= #{ENV['PUPPET_VERSION']}"
else
    puppetversion = ['>= 2.7']
end

gem 'rspec-puppet'
gem 'guard'
gem 'guard-rspec'
gem 'puppet-lint'
gem 'puppet', puppetversion
gem 'guard-shell', '>= 0.4.0'
gem 'libnotify' if RUBY_PLATFORM.downcase.include?("linux")
gem 'growl' if RUBY_PLATFORM.downcase.include?("darwin")
gem 'puppetlabs_spec_helper'
