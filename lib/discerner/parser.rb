module Discerner
  class Parser
    attr_accessor :options
    
    def initialize(options={})
      self.options = options
    end
    
    def parse_dictionaries(str)
      hash_from_file = YAML.load(str)
      dictionaries_from_file = hash_from_file[:dictionaries]
      return error_message 'No dictionaries detected in the file.' if dictionaries_from_file.blank?

      Discerner::Dictionary.transaction do
        # find or initialize dictionaries
        dictionaries_from_file.each do |dictionary_from_file|
          dictionary = Discerner::Dictionary.find_or_initialize_by_name(dictionary_from_file[:name])
          if dictionary.new_record? 
            notification_message "creating dictionary '#{dictionary_from_file[:name]}'"
            dictionary.created_at = Time.now
          else 
            notification_message "dictionary '#{dictionary_from_file[:name]}' already exists and will be updated"
            dictionary.updated_at = Time.now
          end
          dictionary.deleted_at = is_deleted?(dictionary_from_file[:deleted]) ? Time.now : nil
          return error_message 'Dictionary could not be saved:' unless dictionary.save
          
          parameter_categories_from_file = dictionary_from_file[:parameter_categories]
          return error_message 'No parameter categories detected in the file.' if parameter_categories_from_file.blank?
          
          ## find or initialize parameter categories
          parameter_categories_from_file.each do |parameter_category_from_file|
            parameter_category = Discerner::ParameterCategory.where(:name => parameter_category_from_file[:name], :dictionary_id => dictionary.id).first_or_initialize
            if parameter_category.new_record? 
              notification_message "creating parameter category '#{parameter_category_from_file[:name]}'"
              parameter_category.created_at = Time.now
            else 
              notification_message "parameter category '#{parameter_category.name}' already exists and will be updated"
              parameter_category.updated_at = Time.now
            end
            parameter_category.deleted_at = is_deleted?(parameter_category_from_file[:deleted]) ? Time.now : nil
            return error_message 'Parameter category could not be saved:' unless parameter_category.save
            
            parameters_from_file = parameter_category_from_file[:parameters]
            return error_message 'No parameters detected in the file.' if parameters_from_file.blank?
            
            ## find or initialize parameters
            parameters_from_file.each do |parameter_from_file|
              search_identifiers = parameter_from_file[:search]
              
              if search_identifiers.blank? || search_identifiers[:model].blank? || search_identifiers[:attribute].blank?
                return error_message "Parameter search mapping is not defined, add\n:source:\n\t:model: ModelName\n\t:attribute: string to '#{parameter_from_file[:name]}' definition"
              end
              
              parameter = Discerner::Parameter.where(:search_model => search_identifiers[:model].to_s, :search_attribute => search_identifiers[:attribute].to_s, :parameter_category_id => parameter_category.id).first_or_initialize
              
              if parameter.new_record? 
                notification_message "creating parameter '#{parameter_from_file[:name]}'"
                parameter.created_at = Time.now
              else 
                notification_message "parameter '#{parameter.name}' already exists and will be updated"
                parameter.updated_at = Time.now
              end
              return error_message 'Parameter type is not defined in file' if parameter_from_file[:parameter_type].blank?
              
              parameter.parameter_type        = find_or_initialize_parameter_type(parameter_from_file[:parameter_type])
              parameter.name                  = parameter_from_file[:name]
              parameter.deleted_at            = is_deleted?(parameter_from_file[:deleted]) ? Time.now : nil
              parameter.searchable            = to_bool(parameter_from_file[:searchable])
              parameter.exclusive             = parameter_from_file[:exclusive].nil? ? true : to_bool(parameter_from_file[:exclusive])
              parameter.parameter_category_id = parameter_category.id
              return error_message "Parameter #{parameter_from_file[:name].to_s} could not be saved: #{parameter.errors.full_messages}" unless parameter.save
              
              ## find or initialize parameter values
              unless parameter_from_file[:parameter_values].blank?
                parameter_from_file[:parameter_values].each do |parameter_value_from_file|
                  value = parameter_value_from_file[:search_value]
                  find_or_create_parameter_value(parameter, value, parameter_value_from_file[:name]) unless value.blank?
                end
              end

              unless parameter_from_file[:source].blank?
                source = parameter_from_file[:source]
                return error_message "Model and attribute or method must be defined for parameter source" if source[:model].blank? || (source[:attribute].blank? && source[:method].blank?)
                
                model = source[:model].safe_constantize

                return error_message "Model '#{source[:model]}' could not be found" if model.blank?
                return error_message "Only one source is allowed (attribute or method)" if !source[:attribute].blank? && !source[:method].blank?

                unless source[:attribute].blank?
                  return error_message "Unknown attribute '#{source[:attribute]}' for model '#{source[:model]}'" unless model.attribute_method?(source[:attribute])
                  model.send(:all).each do |row|
                    value = row.send(source[:attribute])
                    find_or_create_parameter_value(parameter, value) unless value.blank?
                  end
                end
                unless source[:method].blank? 
                  return error_message "Unknown method '#{source[:method]}' for model '#{source[:model]}'" if not model.respond_to?(source[:method])
                  
                  model.send(source[:method]).each do |value|
                    find_or_create_parameter_value(parameter, value) unless value.blank?
                  end
                end
              end
            end
          end
        end
      end
    end
  
    def parse_operators(str)
       hash_from_file = YAML.load(str)
       
       operators_from_file = hash_from_file[:operators]
       return error_message 'No operators detected in the file.' if operators_from_file.blank?
       
       Discerner::Operator.transaction do
         operators_from_file.each do |operator_from_file|
           operator = Discerner::Operator.find_or_initialize_by_symbol(operator_from_file[:symbol])
           if operator.new_record? 
             notification_message "creating operator '#{operator_from_file[:symbol]}'"
             operator.created_at = Time.now
           else 
             notification_message "operator '#{operator_from_file[:symbol]}' already exists and will be updated"
             operator.updated_at = Time.now
           end
           operator.deleted_at = operator_from_file[:deleted].blank? ? nil : Time.now
           
           unless operator_from_file[:parameter_types].blank?
             operator.parameter_types.destroy_all
             
             operator_from_file[:parameter_types].each do |parameter_type_from_file|
               parameter_type = find_or_initialize_parameter_type(parameter_type_from_file)
               operator.parameter_types << parameter_type
             end
           end
           operator.text = operator_from_file[:text]
           operator.binary  = operator_from_file[:binary]
           operator.deleted_at = operator_from_file[:deleted].blank? ? nil : Time.now
           return error_message 'Operator could not be saved:' unless operator.save
         end
      end
    end
    
    def find_or_initialize_parameter_type(name)
      ## find or initialize parameter type
      parameter_type = Discerner::ParameterType.find_or_initialize_by_name(name)
      if parameter_type.new_record? 
        notification_message "Creating parameter type '#{name}'"
        parameter_type.created_at = Time.now
      else 
        notification_message "Parameter type '#{name}' already exists"
      end
      return error_message "Parameter type #{name} could not be saved: #{parameter_type.errors.full_messages}" unless parameter_type.save
      return parameter_type
    end

    def find_or_create_parameter_value(parameter, value, name=nil)
      parameter_value = Discerner::ParameterValue.where(:search_value => value.to_s, :parameter_id => parameter.id).first_or_initialize
      if parameter_value.new_record? 
        notification_message "Creating parameter value '#{value}'"
        parameter_value.created_at = Time.now
      else 
        notification_message "Parameter value '#{value}' already exists"
        parameter_value.updated_at = Time.now
      end
      parameter_value.name = name || value.to_s
      return error_message "Parameter value #{parameter_value_from_file[:search_value].to_s} could not be saved: #{parameter_value.errors.full_messages}" unless parameter_value.save
    end
    
    def error_message(str)
      puts "ERROR: #{str}" if self.options.has_key?(:trace)
      raise ActiveRecord::Rollback
    end
    
    def notification_message(str)
      puts str if self.options.has_key?(:trace)
    end
    
    def to_bool(s)
      return true if s == true || s =~ (/^(true|t|yes|y|1)$/i)
      return false if s == false || s.blank? || s =~ (/^(false|f|no|n|0)$/i)
      error_message("invalid value for Boolean: \"#{s}\"")
    end
    
    def is_deleted?(param)
      return false if param.blank?
      to_bool(param)
    end
  end
end
