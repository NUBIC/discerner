$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem"s version:
require "discerner/version"
require "discerner/parser"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "discerner"
  s.version     = Discerner::VERSION
  s.authors     = ["Michael Gurley, Yulia Bushmanova"]
  s.email       = ["m-gurley@northwestern.edu, y.bushmanova@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "Rails engine that provides dictionary-based search functionality for SQLServer datamart-based applications"
  s.description = "Rails engine that provides dictionary-based search functionality for SQLServer datamart-based applications"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.1"
  s.add_dependency "jquery-rails"
  s.add_dependency "haml"
  s.add_dependency "sass"
  
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "shoulda"
  s.add_development_dependency 'rspec-rails', '~> 2.6'
  s.add_development_dependency 'rails', '~> 3.1'
  s.add_development_dependency 'jquery-rails'
  s.add_development_dependency 'factory_girl_rails', '~> 1.7'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'cucumber-rails'
  s.add_development_dependency 'ansi'
end
