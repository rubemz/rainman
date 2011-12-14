#!/usr/bin/env rake
require "bundler/gem_tasks"
begin
  require 'rspec/core/rake_task'
rescue LoadError
  puts "Please install rspec (bundle install)"
  exit
end

RSpec::Core::RakeTask.new :spec
task :default => :spec
