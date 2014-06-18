$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'discerner/version'
require 'discerner/parser'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'discerner'
  s.version     = Discerner::VERSION
  s.licenses    = ['MIT']
  s.authors     = ['Michael Gurley, Yulia Bushmanova']
  s.email       = ['m-gurley@northwestern.edu, y.bushmanova@gmail.com']
  s.summary     = 'Rails engine that provides dictionary-based search functionality for SQLServer datamart-based applications'
  s.description = 'Rails engine that provides dictionary-based search functionality for SQLServer datamart-based applications'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['MIT-LICENSE', 'Rakefile', 'README.md']

  s.required_ruby_version = '>= 1.9.0'

  s.add_dependency 'rails', '~> 3.2', '>= 3.2.0'
  s.add_dependency 'jquery-rails', '~> 3.1', '>= 3.1.0'
  s.add_dependency 'jquery-ui-rails', '~> 4.2', '>= 4.2.1'
  s.add_dependency 'haml', '~> 4.0.5', '>= 4.0.5'
  s.add_dependency 'sass-rails', '~> 3.2.6', '>= 3.2.6'

  s.add_development_dependency 'sqlite3', '~> 1.3.9', '>= 1.3.9'
  s.add_development_dependency 'rspec-rails', '~> 2.14.2', '>= 2.14.2'
  s.add_development_dependency 'factory_girl_rails', '~> 4.4.1', '>= 4.4.1'
  s.add_development_dependency 'cucumber-rails', '~> 1.4.0', '>= 1.4.0'
  s.add_development_dependency 'capybara', '~> 2.2.1', '>= 2.2.1'
  s.add_development_dependency 'selenium-webdriver', '~> 2.41.0', '>= 2.41.0'
  s.add_development_dependency 'database_cleaner', '~> 1.2.0', '>= 1.2.0'
  s.add_development_dependency 'ansi', '~> 1.4.3', '>= 1.4.3'
  s.add_development_dependency 'sprockets', '~> 2.2.2', '>= 2.2.2'
  s.add_development_dependency 'nubic-gem-tasks', '~> 1.0', '>= 1.0.0'
  s.add_development_dependency 'yard', '~> 0.8.7.3', '>= 0.8.7.3'
  s.add_development_dependency 'redcarpet', '~> 3.1.1', '>= 3.1.1'
end
