$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'discerner/version'
require 'discerner/parser'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'discerner'
  s.version     = Discerner::VERSION
  s.authors     = ['Michael Gurley, Yulia Bushmanova']
  s.email       = ['m-gurley@northwestern.edu, y.bushmanova@gmail.com']
  s.summary     = 'Rails engine that provides dictionary-based search functionality for SQLServer datamart-based applications'
  s.description = 'Rails engine that provides dictionary-based search functionality for SQLServer datamart-based applications'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['MIT-LICENSE', 'Rakefile', 'README.rdoc']

  s.add_dependency 'rails', '3.2.17'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'jquery-ui-rails'
  s.add_dependency 'haml', '3.1.8'
  s.add_dependency 'sass-rails',   '~> 3.2.0'
  s.add_dependency 'i18n'


  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'cucumber-rails'
  s.add_development_dependency 'capybara', '1.1.3'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'ansi'
  s.add_development_dependency 'sprockets'
  s.add_development_dependency 'factory_girl', '2.3.2'
  s.add_development_dependency 'nokogiri', '~>1.5.0'
  s.add_development_dependency 'rubyzip', '0.9.9'
  s.add_development_dependency 'shoulda', '3.3.0'
end
