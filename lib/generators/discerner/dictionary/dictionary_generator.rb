module Discerner
  class DictionaryGenerator < Rails::Generators::Base
    class_option "no-load",   :type => :boolean
    class_option "no-models", :type => :boolean
    class_option "no-views",  :type => :boolean
    
    source_root File.expand_path('../templates', __FILE__)
    argument :dictionary_file_path, :type => :string
    
    def parse_dictionary_file
      rake("discerner:setup:dictionaries FILE=#{dictionary_file_path}") unless options["no-load"]
    end
    
    def create_stub_dictionary_files
      Discerner::Dictionary.not_deleted.each do |dictionary|
        create_dictionary_class(dictionary) unless options["no-models"]
        create_dictionary_view(dictionary)  unless options["no-views"]
      end
    end
    
    def add_excel_mime_type
      inject_into_file("#{Rails.root}/config/initializers/mime_types.rb", 'Mime::Type.register "application/xls", :xls', :after => "# Be sure to restart your server when you modify this file.\n")
    end
    
    private
      def create_dictionary_class(dictionary)
        @class_name = dictionary.parameterized_name.camelize
        template "model.rb", "#{Discerner::Engine.paths['app/models']}/#{dictionary.parameterized_name}.rb"
      end

      def create_dictionary_view(dictionary)
        @dictionary_name = dictionary.name
        empty_directory "#{Discerner::Engine.paths['app/views']}/discerner/dictionaries/#{dictionary.parameterized_name}"
        template "view.html.haml", "#{Discerner::Engine.paths['app/views']}/discerner/dictionaries/#{dictionary.parameterized_name}/_results.html.haml"
        template "show.xls.erb", "#{Discerner::Engine.paths['app/views']}/discerner/dictionaries/#{dictionary.parameterized_name}/show.xls.erb"
      end
  end
end