# desc "Explaining what the task does"
# task :discerner do
#   # Task goes here
# end

namespace :discerner do
  namespace :setup do
    desc 'Load dictionaries (specify file to parse with FILE=myfile.yml), --trace gives back tracing messages, --prune_dictionaries removes dictionaries that are not specified in the definition file unless they are used in search'
    task dictionaries: :environment do
      file = ENV["FILE"]
      raise "File name has to be provided" if file.blank?
      raise "File does not exist: #{file}" unless FileTest.exists?(file)
      parser = Discerner::Parser.new(trace: Rake.application.options.trace, prune_dictionaries: Rake.application.options.prune_dictionaries)
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

  desc "Delete dictionary (specify dictionary to remove with NAME='My dictionary name')"
  task delete_dictionary: :environment do
    dictionary = Discerner::Dictionary.where(name: ENV["NAME"]).last
    raise "Dictionary does not exist: #{ENV["NAME"]}" if dictionary.blank?
    Discerner::Search.where(dictionary_id: dictionary.id).destroy_all
    dictionary.delete
  end
end
