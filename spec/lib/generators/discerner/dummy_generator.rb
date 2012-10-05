## another shameless steal from forem git://github.com/radar/forem.git
# and https://github.com/spree/spree/blob/master/core/lib/generators/spree/dummy/dummy_generator.rb

require 'rails/generators'
require 'rails/generators/rails/app/app_generator'
require 'active_support/core_ext/hash'

module Discerner
  class DummyGenerator < Rails::Generators::Base
    desc "Creates blank Rails application and mounts Discerner"

    def self.source_paths
      paths = self.superclass.source_paths
      paths << File.expand_path('../templates', __FILE__)
      paths.flatten
    end

    PASSTHROUGH_OPTIONS = [
      :skip_active_record, :skip_javascript, :database, :javascript, :quiet, :pretend, :force, :skip
    ]

    def generate_test_dummy
      opts = (options || {}).slice(*PASSTHROUGH_OPTIONS)
      opts[:database] = 'sqlite3' if opts[:database].blank?
      opts[:force] = true
      opts[:skip_bundle] = true
      opts[:old_style_hash] = true

      puts "Generating dummy Rails application..."
      invoke Rails::Generators::AppGenerator, [ File.expand_path(dummy_path, destination_root) ], opts
    end

    def test_dummy_config
      inject_into_file "#{dummy_path}/config/routes.rb",
        "\nmount Discerner::Engine, :at => '/discerner'\n",
        :after => "Dummy::Application.routes.draw do\n"
    end

    def test_dummy_clean
      inside dummy_path do
        remove_file ".gitignore"
        remove_file "doc"
        remove_file "Gemfile"
        remove_file "lib/tasks"
        remove_file "app/assets/images/rails.png"
        remove_file "app/assets/javascripts/application.js"
        remove_file "public/index.html"
        remove_file "public/robots.txt"
        remove_file "README"
        remove_file "test"
        remove_file "vendor"
        remove_file "spec"
      end
    end
    
    protected

      def dummy_path
        'spec/dummy'
      end

      def application_definition
        @application_definition ||= begin
          dummy_application_path = File.expand_path("#{dummy_path}/config/application.rb", destination_root)
          unless options[:pretend] || !File.exists?(dummy_application_path)
            contents = File.read(dummy_application_path)
            contents[(contents.index("module #{module_name}"))..-1]
          end
        end
      end
      alias :store_application_definition! :application_definition

      def gemfile_path
        '../../../../Gemfile'
      end
      
      def remove_directory_if_exists(path)
        remove_dir(path) if File.directory?(path)
      end
  end
end
