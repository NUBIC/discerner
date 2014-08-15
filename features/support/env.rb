# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a
# newer version of cucumber-rails. Consider adding your own code to a new file
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.
require 'ansi/code'
ENV["RAILS_ENV"] ||= "test"

begin
  require File.expand_path("../../../test/dummy/config/environment.rb", __FILE__)
rescue LoadError
  puts ANSI.red{ "ERROR: You must execute `bundle exec rake discerner:test:dummy_app` to run cucumber features"}
end

ENV["RAILS_ROOT"] ||= File.dirname(__FILE__) + "../../../test/dummy"

require 'cucumber/rails'
require 'factory_girl'
require 'selenium/webdriver'
require 'cucumber/rspec/doubles'

FactoryGirl.find_definitions

# Capybara defaults to XPath selectors rather than Webrat's default of CSS3. In
# order to ease the transition to Capybara we set the default here. If you'd
# prefer to use XPath just remove this line and adjust any selectors in your
# steps to use the XPath syntax.

Capybara.configure do |config|
  config.default_selector = :css
  config.ignore_hidden_elements = false
end

# By default, any exception happening in your Rails application will bubble up
# to Cucumber so that your scenario will fail. This is a different from how
# your application behaves in the production environment, where an error page will
# be rendered instead.
#
# Sometimes we want to override this default behaviour and allow Rails to rescue
# exceptions and display an error page (just like when the app is running in production).
# Typical scenarios where you want to do this is when you test your error pages.
# There are two ways to allow Rails to rescue exceptions:
#
# 1) Tag your scenario (or feature) with @allow-rescue
#
# 2) Set the value below to true. Beware that doing this globally is not
# recommended as it will mask a lot of errors for you!
#
ActionController::Base.allow_rescue = false

# Remove/comment out the lines below if your app doesn't have a database.
# For some databases (like MongoDB and CouchDB) you may need to use :truncation instead.
begin
  DatabaseCleaner.strategy = :truncation
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

# You may also want to configure DatabaseCleaner to use different strategies for certain features and scenarios.
# See the DatabaseCleaner documentation for details. Example:
#
  # Before('@no-txn,@selenium,@culerity,@celerity,@javascript') do
  #   # { except: [:widgets] } may not do what you expect here
  #   # as tCucumber::Rails::Database.javascript_strategy overrides
  #   # this setting.
  #   DatabaseCleaner.strategy = :truncation
  # end
#
#   Before('~@no-txn', '~@selenium', '~@culerity', '~@celerity', '~@javascript') do
#     DatabaseCleaner.strategy = :transaction
#   end
#

# Possible values are :truncation and :transaction
# The :transaction strategy is faster, but might give you threading problems.
# See https://github.com/cucumber/cucumber-rails/blob/master/features/choose_javascript_database_strategy.feature
Cucumber::Rails::Database.javascript_strategy = :truncation

Capybara.register_driver :chrome do |app|
  prefs = {"download" => {"default_directory" => DownloadHelpers::PATH.to_s, "directory_upgrade" => true, "extensions_to_open" => ""}}
  caps = Selenium::WebDriver::Remote::Capabilities.chrome
  caps['chromeOptions'] = {'prefs' => prefs}
  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: caps)
end

Capybara.javascript_driver = :chrome

