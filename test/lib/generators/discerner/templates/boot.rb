require 'rubygems'
gemfile = File.expand_path("<%= gemfile_path %>", __FILE__)

if File.exist?(gemfile)
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
end