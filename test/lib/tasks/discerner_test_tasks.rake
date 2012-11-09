## shameless steal from forem git://github.com/radar/forem.git
namespace :discerner do
  namespace :test do
    desc "Generates a dummy app for testing and runs migrations"
    task :dummy_app => [:setup_dummy_app, :migrate_dummy_app]

    desc "Setup dummy app"
    task :setup_dummy_app do
      require 'rails'
      require File.expand_path('../../generators/discerner/dummy_generator', __FILE__)

      Discerner::DummyGenerator.start %w(--quiet)
    end
    
    task :migrate_dummy_app do
      puts "Setting up dummy database..."
      generator_tasks = 'rails generate discerner:install'
      task_params = [%Q{ bundle exec rake -f test/dummy/Rakefile discerner:install:migrations }]
      task_params << %Q{ db:drop db:create db:migrate db:seed db:test:prepare }
      system generator_tasks
      system task_params.join(' ')
    end

    desc "Destroy dummy app"
    task :destroy_dummy_app do
      FileUtils.rm_rf "test/dummy" if File.exists?("test/dummy")
    end
  end
end
