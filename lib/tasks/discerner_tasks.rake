# desc "Explaining what the task does"
# task :discerner do
#   # Task goes here
# end

namespace :discerner do
  namespace :setup do
    desc 'Load dictionaries'
    task :dictionaries => :environment do
      file = ENV["FILE"]
      raise "File name has to be provided" if file.blank?
      raise "File does not exist: #{file}" unless FileTest.exists?(file)
      parser = Discerner::Parser.new(:trace => Rake.application.options.trace)
      parser.parse_dictionaries(File.read(file))
    end
  end
  desc 'Unload all dictionaries'
  task :unload_dictionaries => :environment do
    Discerner::Search.destroy_all
    Discerner::Dictionary.destroy_all
  end
end
