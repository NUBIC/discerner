# desc "Explaining what the task does"
# task :discerner do
#   # Task goes here
# end

namespace :discerner do
  namespace :setup do
    desc 'Load the database with operators'
    task :operators => :environment do
      file = ENV["FILE"] || File.join(Discerner::Engine.root, 'lib/setup/operators.yml')
      
      raise "File does not exist: #{file}" unless FileTest.exists?(file)
      parser = Discerner::Parser.new(:trace => Rake.application.options.trace)
      parser.parse_operators(File.read(file))  
    end
    
    desc 'Load dictionaries'
    task :dictionaries => :environment do
      file = ENV["FILE"]
      raise "File name has to be provided" if file.blank?
      raise "File does not exist: #{file}" unless FileTest.exists?(file)
      parser = Discerner::Parser.new(:trace => Rake.application.options.trace)
      parser.parse_dictionaries(File.read(file))
    end
  end
end
