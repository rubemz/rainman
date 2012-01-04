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

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -r ./lib/rainman.rb -I ./lib -r ./example/domain.rb"
end
