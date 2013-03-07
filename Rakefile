#!/usr/bin/env rake
begin
  require 'bundler/setup'
  require 'cucumber/rake/task'
  require 'rspec/core/rake_task'
end

APP_RAKEFILE = File.expand_path("../test/dummy/Rakefile", __FILE__)
$:.unshift File.join(File.dirname(__FILE__), 'spec','support')

load 'rails/tasks/engine.rake' if File.exists?(APP_RAKEFILE)
load 'lib/tasks/discerner_tasks.rake'
load 'test/lib/tasks/discerner_test_tasks.rake'

RSpec::Core::RakeTask.new(:spec)
task :default => :spec

namespace :cucumber do
  Cucumber::Rake::Task.new(:wip, 'Run features that are being worked on') do |t|
    t.profile = 'wip'
  end

  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "features --format pretty"
  end
end

task :cucumber => 'cucumber:features'

Bundler::GemHelper.install_tasks
