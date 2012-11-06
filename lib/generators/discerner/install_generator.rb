# encoding: UTF-8
require "rails/generators"

module Discerner
  class InstallGenerator < Rails::Generators::Base
    def self.source_paths
      paths = self.superclass.source_paths
      paths << File.expand_path("../templates", __FILE__)
      paths.flatten
    end
    
    def sample_dictionary
      empty_directory "#{Discerner::Engine.paths['lib']}/setup"
      copy_file "dictionary.yml", "#{Discerner::Engine.paths['lib']}/setup/dictionary.yml"
    end
  end
end