require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint'

PuppetLint.configuration.ignore_paths = ["vendor/**/*.pp"]

task :default => [:spec, :lint]
