# encoding: UTF-8
require "rails/generators"

module Discerner
  class InstallGenerator < Rails::Generators::Base
    class_option "no-migrate", :type => :boolean
    class_option "customize-all", :type => :boolean
    class_option "customize-controllers", :type => :boolean
    class_option "customize-models", :type => :boolean
    class_option "customize-helpers", :type => :boolean
    class_option "current-user-helper", :type => :string

    def self.source_paths
      paths = self.superclass.source_paths
      paths << File.expand_path("../templates", __FILE__)
      paths.flatten
    end

    desc "Used to install Discerner"

    def install_migrations
      unless options["no-migrations"]
        puts "Copying over Discerner migrations..."
        Dir.chdir(Rails.root) do
          `rake discerner:install:migrations`
        end
      end
    end

    ## shameless steal from forem git://github.com/radar/forem.git
    def add_discerner_user_method
      current_user_helper = options["current-user-helper"].presence ||
                            ask("What is the current_user helper called in your app? [current_user]").presence ||
                            'current_user if defined?(current_user)'
      puts "Defining discerner_user method inside ApplicationController..."

      discerner_user_method = %Q{
  def discerner_user
    #{current_user_helper}
  end
  helper_method :discerner_user
}
      inject_into_file("#{Rails.root}/app/controllers/application_controller.rb",
                       discerner_user_method,
                       :after => "ActionController::Base\n")
    end

    def add_discerner_view_helpers
      puts "Defining discerner view helpers inside ApplicationHelper..."

      discerner_helper_methods = %Q{
  def export_discerner_results?
    true
  end

  def show_discerner_results?
    true
  end

  def enable_combined_searches?
    true
  end
}
      inject_into_file("#{Rails.root}/app/helpers/application_helper.rb",
                       discerner_helper_methods,
                       :after => "ApplicationHelper\n")
    end

    def run_migrations
      unless options["no-migrate"]
        puts "Running rake db:migrate"
        `rake db:migrate`
      end
    end

    def seed_database_with_operators
      unless options["no-migrate"]
        puts "Running rake discerner:setup:operators"
        `rake discerner:setup:operators`
      end
    end

    def mount_engine
      puts "Mounting Discerner::Engine at \"/\" in config/routes.rb..."
      insert_into_file("#{Rails.root}/config/routes.rb", :after => /routes.draw.do\n/) do
        %Q{  mount Discerner::Engine, :at => "/"\n}
      end
    end

    def sample_dictionary
      empty_directory "#{Discerner::Engine.paths['lib']}/setup"
      copy_file "dictionaries.yml", "#{Discerner::Engine.paths['lib']}/setup/dictionaries.yml"
    end

    def make_customizable
      if options["customize-all"] || options["customize-controllers"]
        controllers_directory = "#{Discerner::Engine.paths['app']}/controllers/discerner"
        empty_directory controllers_directory
        copy_file "controllers/searches_controller.rb", "#{controllers_directory}/searches_controller.rb"
        copy_file "controllers/parameters_controller.rb", "#{controllers_directory}/parameters_controller.rb"
        copy_file "controllers/export_parameters_controller.rb", "#{controllers_directory}/export_parameters_controller.rb"
      end

      if options["customize-all"] || options["customize-helpers"]
        empty_directory "#{Discerner::Engine.paths['app']}/helpers/discerner"
        copy_file "helpers/searches_helper.rb", "#{Discerner::Engine.paths['app']}/helpers/discerner/searches_helper.rb"
      end

      if options["customize-all"] || options["customize-models"]
        empty_directory "#{Discerner::Engine.paths['app']}/models/discerner"
        copy_file "models/dictionary.rb", "#{Discerner::Engine.paths['app']}/models/discerner/dictionary.rb"
        copy_file "models/export_parameter.rb", "#{Discerner::Engine.paths['app']}/models/discerner/export_parameter.rb"
        copy_file "models/operator.rb", "#{Discerner::Engine.paths['app']}/models/discerner/operator.rb"
        copy_file "models/parameter_category.rb", "#{Discerner::Engine.paths['app']}/models/discerner/parameter_category.rb"
        copy_file "models/parameter_type.rb", "#{Discerner::Engine.paths['app']}/models/discerner/parameter_type.rb"
        copy_file "models/parameter_value.rb", "#{Discerner::Engine.paths['app']}/models/discerner/parameter_value.rb"
        copy_file "models/parameter.rb", "#{Discerner::Engine.paths['app']}/models/discerner/parameter.rb"
        copy_file "models/search_combination.rb", "#{Discerner::Engine.paths['app']}/models/discerner/search_combination.rb"
        copy_file "models/search_parameter_value.rb", "#{Discerner::Engine.paths['app']}/models/discerner/search_parameter_value.rb"
        copy_file "models/search_parameter.rb", "#{Discerner::Engine.paths['app']}/models/discerner/search_parameter.rb"
        copy_file "models/search.rb", "#{Discerner::Engine.paths['app']}/models/discerner/search.rb"
      end
    end

    def finished
      output = "\n\n" + ("*" * 53)
      output += "\nDone! Discerner has been successfully installed. Here's what happened:\n\n"
      output += "-- Discerner's migrations were copied over into db/migrate.\n"
      output += "-- A new method called `discerner_user` was inserted into your ApplicationController. This lets Discerner know what the current user of your application is.\n"

      unless options["no-migrate"]
        output += "-- `rake db:migrate` was run, running all the migrations against your database.\n"
        output += "-- Seed operators were loaded into your database.\n"
      end
      output += "-- The engine was mounted in your config/routes.rb file using this line:
        mount Discerner::Engine, :at => \"/\""
      output += "\nIf you want to change where the searches are located, just change the \"/searches\" path at the end of this line to whatever you want."
      output += "\n--  Sample search dictionary was copied into lib/setup. If you want to try it out, run `rails generate discerner:dictionary lib/setup/dictionaries.yml`. This will:\n"
      output += "\n-- parse dictionary definitions from lib/setup/dictionaries.yml into the database."
      output += "\n-- create corresponsing classes"
      output += "\n-- create corresponsing views for results display"
      puts output
    end
  end
end