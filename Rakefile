#!/usr/bin/env rake
begin
  require 'bundler/setup'
end

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)

if File.exists?(APP_RAKEFILE)
  load 'rails/tasks/engine.rake'
end

load 'lib/tasks/discerner_tasks.rake'

$:.unshift File.join(File.dirname(__FILE__), 'spec','support')
load 'spec/lib/tasks/discerner_spec_tasks.rake'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

Bundler::GemHelper.install_tasks
