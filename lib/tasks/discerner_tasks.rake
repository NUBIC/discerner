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
  
      operators = YAML.load(File.read("#{file}"))
      
      Discerner::Operator.transaction do
        operators.each do |operator_from_file|
          operator = Discerner::Operator.where(:symbol => operator_from_file[:operator][:symbol]).first

          if operator
            puts "#{operator_from_file[:operator][:symbol]} in operators already exists"
          else
            puts "Creating operator #{operator_from_file[:operator][:symbol]}"
            operator = Discerner::Operator.new(:symbol => operator_from_file[:operator][:symbol])
            operator.created_at = Time.now
          end

          if operator_from_file[:operator][:parameter_types]
            operator.parameter_types.destroy_all

            operator_from_file[:operator][:parameter_types].each do |parameter_type_from_file|
              parameter_type = Discerner::ParameterType.where(:name => parameter_type_from_file)

              if parameter_type.empty?
                puts "Creating parameter_type #{parameter_type_from_file}"
                parameter_type = Discerner::ParameterType.new(:name => parameter_type_from_file)
                parameter_type.created_at = Time.now
                parameter_type.save
              end
              operator.parameter_types << parameter_type
            end
          end
          operator.text = operator_from_file[:operator][:text]
          operator.binary  = operator_from_file[:operator][:binary]
          operator.deleted_at = Time.now unless operator_from_file[:operator][:deleted].blank?
          raise ActiveRecord::Rollback unless operator.save
        end
      end
    end
  end
end