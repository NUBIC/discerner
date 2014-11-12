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
  s.summary     = 'Rails engine that provides dictionary-based search functionality'
  s.description = 'Discerner is an engine for Rails that provides basic search UI, search reqults export UI and allows to configure available search parameters/values. Discerner is not aimed to be a SQL-generator, but it allows the host application to access stored search conditions and provide search results.'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['MIT-LICENSE', 'Rakefile', 'README.md']

  s.required_ruby_version = '>= 1.9.0'

  s.add_dependency 'rails', '~> 4.1', '>= 4.1.0'
  s.add_dependency 'jquery-rails', '~> 3.1', '>= 3.1.0'
  s.add_dependency 'haml', '~> 4.0', '>= 4.0.5'
  s.add_dependency 'sass-rails', '~> 4.0', '>= 4.0.1'

  s.add_development_dependency 'sqlite3', '~> 1.3.9', '>= 1.3.9'
  s.add_development_dependency 'rspec-rails', '~> 3.0.2', '>= 3.0.2'
  s.add_development_dependency 'factory_girl_rails', '~> 4.4.1', '>= 4.4.1'
  s.add_development_dependency 'capybara', '~> 2.4.1', '>= 2.4.1'
  s.add_development_dependency 'selenium-webdriver', '~> 2.42.0', '>= 2.42.0'
  s.add_development_dependency 'database_cleaner', '~> 1.3.0', '>= 1.3.0'
  s.add_development_dependency 'ansi', '~> 1.4.3', '>= 1.4.3'
  s.add_development_dependency 'sprockets', '~> 2.12.1', '>= 2.12.1'
  s.add_development_dependency 'yard', '~> 0.8.7.4', '>= 0.8.7.4'
  s.add_development_dependency 'redcarpet', '~> 3.1.2', '>= 3.1.2'
end
