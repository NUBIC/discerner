## shameless steal from forem git://github.com/radar/forem.git
namespace :discerner do
  namespace :test do
    desc "Generates a dummy app for testing and runs migrations"
    task :dummy_app => [:setup_dummy_app, :generate_dummy_discerner]

    desc "Setup dummy app"
    task :setup_dummy_app do
      puts "Setting up dummy application ........."
      require 'rails'
      require File.expand_path('../../generators/discerner/dummy_generator', __FILE__)

      Discerner::DummyGenerator.start %w(--quiet)
    end
    
    task :generate_dummy_discerner do
      Dir.chdir('test/dummy') if File.exists?("test/dummy")
      
      discerner_generator_task  = %Q{ rails generate discerner:install}
      dictionary_generator_task = %Q{ rails generate discerner:dictionary lib/setup/dictionaries.yml}
      task_params = [%Q{ bundle exec rake -f test/dummy/Rakefile db:test:prepare }]
      
      puts "Setting up Discerner ........."
      system discerner_generator_task
      
      puts "Setting up dictionaries ........."
      system dictionary_generator_task
      
      puts "Setting up test database ........."
      system task_params.join(' ')
    end

    desc "Destroy dummy app"
    task :destroy_dummy_app do
      FileUtils.rm_rf "test/dummy" if File.exists?("test/dummy")
    end
  end
end
