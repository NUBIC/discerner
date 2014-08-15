# desc "Explaining what the task does"
# task :discerner do
#   # Task goes here
# end

namespace :discerner do
  namespace :setup do
    desc 'Load dictionaries (specify file to parse with FILE=myfile.yml) '
    task dictionaries: :environment do
      file = ENV["FILE"]
      raise "File name has to be provided" if file.blank?
      raise "File does not exist: #{file}" unless FileTest.exists?(file)
      parser = Discerner::Parser.new(trace: Rake.application.options.trace)
      parser.parse_dictionaries(File.read(file))
    end

    desc 'Load operators'
    task operators: :environment do
      file = File.join(Discerner::Engine.root, 'lib/setup/operators.yml')
      raise "File does not exist: #{file}" unless FileTest.exists?(file)
      Discerner::Parser.new(trace: Rake.application.options.trace).parse_operators(File.read(file))
    end
  end

  desc 'Unload all dictionaries'
  task unload_dictionaries: :environment do
    Discerner::Search.destroy_all
    Discerner::Dictionary.destroy_all
  end
end
