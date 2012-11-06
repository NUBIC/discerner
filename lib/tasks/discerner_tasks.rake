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
    
    desc 'Load the dictionary'
    task :dictionary => :environment do
      file = ENV["FILE"] || File.join(Discerner::Engine.paths['lib'], 'setup/dictionary.yml')
      raise "File does not exist: #{file}" unless FileTest.exists?(file)
      
      parameter_categories = YAML.load(File.read(file))

      ## find or create groups
      parameter_categories.each do |parameter_category_from_file|
        parameter_category = Discerner::ParameterCategory.where(:name => parameter_category_from_file[:group][:name]).first

        if parameter_category
          puts "Group #{parameter_category_from_file[:group][:name]} already exists"
        else
          puts "Creating group #{parameter_category_from_file[:group][:name]}"
          parameter_category = Discerner::ParameterCategory.new(:name => parameter_category_from_file[:group][:name])
          parameter_category.created_at = Time.now
        end

        ## find or create parameters
        parameter_category_from_file[:group][:parameters].each do |parameter_from_file|
          parameter = Discerner::Parameter.where(:database_name => parameter_from_file[:database_name]).first
          if parameter
            puts "Discerner::Parameter #{parameter_from_file[:database_name]} already exists and will be updated"
          else
            puts "Creating parameter #{parameter_from_file[:database_name]}"
            parameter = Discerner::Parameter.new(:database_name => parameter_from_file[:database_name])
            parameter.created_at = Time.now
          end

          ## find or create parameter types
          parameter_type = Discerner::ParameterType.where(:name => parameter_from_file[:parameter_type]).first
          unless parameter_type
            puts "Creating parameter_type #{parameter_from_file[:parameter_type]}"
            parameter_type = Discerner::ParameterType.new(:name => parameter_from_file[:parameter_type])
            parameter_type.created_at = Time.now
            parameter_type.save
          end
          parameter.database_name = parameter_from_file[:database_name]
          parameter.name = parameter_from_file[:name]
          parameter.parameter_type = parameter_type
          parameter.deleted_at = Time.now unless parameter_from_file[:deleted].blank?
          parameter.save

          ## find or create parameter values
          if parameter_from_file[:parameter_values]
            parameter_from_file[:parameter_values].each do |parameter_value_from_file|
              parameter_value = parameter.find_or_create_parameter_value(parameter_value_from_file[:name])
              parameter_value.deleted_at = Time.now unless parameter_value_from_file[:deleted].blank?
              parameter_value.save
              parameter.parameter_values << parameter_value
            end
          elsif parameter_from_file[:source]
            source = parameter_from_file[:source]
            if source[:model].blank? || source[:attribute].blank?
              puts "Model and attribute must be defined for parameter source"
            else
              model = source[:model].safe_constantize
              if model.blank?
                error "Model #{source[:model]} could not be found"  
              elsif not model.respond_to?(source[:attribute])
                error "Unknown attribute #{source[:attribute]} for model #{source[:model]}" 
              else
                model.all.each do |row|
                  parameter_value = parameter.find_or_create_parameter_value(row.send(source[:attribute]))
                  parameter.parameter_values << parameter_value
                end
              end
            end
          end
          parameter_category.parameters << parameter
        end
        parameter_category.save
      end
    end
  end
end

def error(message)
  puts "ERROR: #{message}"
end