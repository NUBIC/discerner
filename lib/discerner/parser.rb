module Discerner
  class Parser
    attr_accessor :options, :errors
    
    def initialize(options={})
      self.options = options
      self.errors = []
    end
    
    def parse_dictionaries(str)
      hash_from_file = YAML.load(str)
      
      # find or initialize dictionaries
      dictionaries_from_file = hash_from_file[:dictionaries]
      error_message 'No dictionaries detected.' if dictionaries_from_file.blank?

      Discerner::Dictionary.transaction do
        dictionaries_from_file.each do |dictionary_from_file|
          dictionary = parse_dictionary(dictionary_from_file)
          
          ## find or initialize parameter categories
          parameter_categories_from_file = dictionary_from_file[:parameter_categories]
          error_message 'no parameter categories detected' if parameter_categories_from_file.blank?

          parameter_categories_from_file.each do |parameter_category_from_file|
            parameter_category = parse_parameter_category(dictionary, parameter_category_from_file)
            
            ## find or initialize parameters
            parameters_from_file = parameter_category_from_file[:parameters]
            error_message 'no parameters detected' if parameters_from_file.blank?
            
            parameters_from_file.each do |parameter_from_file|
              parameter = parse_parameter(parameter_category, parameter_from_file)
              
              search_identifiers = parameter_from_file[:search]
              unless search_identifiers.blank?
                ## find or initialize parameter values
                unless search_identifiers[:parameter_values].blank?
                  search_identifiers[:parameter_values].each do |parameter_value_from_file|
                    parse_parameter_value(parameter, parameter_value_from_file)
                  end
                end

                unless search_identifiers[:source].blank?
                  load_parameter_value_from_source(parameter, search_identifiers[:source])
                end
              end
            end
          end
        end
      end
    end
    
    def parse_dictionary(hash)
      error_message 'dictionary definition was not provided' if hash.blank?
      
      dictionary_name = hash[:name]
      error_message 'dictionary name cannot be blank' if dictionary_name.blank?
      notification_message "processing dictionary '#{dictionary_name}'"
      
      dictionary = Discerner::Dictionary.find_or_initialize_by_name(dictionary_name)
      dictionary.deleted_at = is_deleted?(hash[:deleted]) ? Time.now : nil
      
      if dictionary.new_record? 
        notification_message "creating dictionary ..."
        dictionary.created_at = Time.now
      else 
        notification_message "updating dictionary ..."
        dictionary.updated_at = Time.now
      end
      error_message "dictionary could not be saved: #{dictionary.errors.full_messages}", dictionary_name unless dictionary.save
      notification_message 'dictionary saved'
      dictionary 
    end
    
    def parse_parameter_category(dictionary, hash)
      error_message 'parameter category definition was not provided' if hash.blank?
      
      parameter_category_name = hash[:name]
      error_message 'parameter category name cannot be blank' if parameter_category_name.blank?
      notification_message "processing parameter category  '#{parameter_category_name}'"
      
      parameter_category = Discerner::ParameterCategory.where(:name => parameter_category_name, :dictionary_id => dictionary.id).first_or_initialize
      parameter_category.deleted_at = is_deleted?(hash[:deleted]) ? Time.now : nil
      if parameter_category.new_record? 
        notification_message "creating parameter category ..."
        parameter_category.created_at = Time.now
      else 
        notification_message "updating parameter category ..."
        parameter_category.updated_at = Time.now
      end
      error_message "parameter category could not be saved: #{parameter_category.errors.full_messages}", parameter_category_name unless parameter_category.save
      notification_message 'parameter category saved'
      parameter_category
    end
  
    def parse_parameter(parameter_category, hash)
      error_message 'parameter definition was not provided' if hash.blank?
      
      parameter_name = hash[:name]
      error_message 'parameter name cannot be blank' if parameter_name.blank?
  
      notification_message "processing parameter '#{parameter_name}'"
      unique_identifier = hash[:unique_identifier]
      error_message "unique_identifier cannot be blank", parameter_name if unique_identifier.blank?
      
      existing_parameter    = Discerner::Parameter.includes({:parameter_category => :dictionary}).where('discerner_parameters.unique_identifier = ? and discerner_dictionaries.id = ?', unique_identifier, parameter_category.dictionary.id).first
      parameter             = existing_parameter || Discerner::Parameter.new(:unique_identifier => unique_identifier, :parameter_category => parameter_category) 
      parameter.name        = parameter_name
      parameter.deleted_at  = is_deleted?(hash[:deleted]) ? Time.now : nil
      parameter.exclusive   = hash[:exclusive].nil? ? true : to_bool(hash[:exclusive])

      search_identifiers = hash[:search]
      unless search_identifiers.blank?
        error_message "Searchable parameter should search model, search method and parameter_type defined." if 
          search_identifiers[:model].blank? || search_identifiers[:method].blank? || search_identifiers[:parameter_type].blank?
      
        parameter.search_model      = search_identifiers[:model].to_s
        parameter.search_method     = search_identifiers[:method].to_s
        parameter.parameter_type    = find_or_initialize_parameter_type(search_identifiers[:parameter_type]) 
      end
      
      export_identifiers = hash[:export]
      unless export_identifiers.blank?
        error_message "Exportable parameter should export model and export method defined." if 
          export_identifiers[:model].blank? || export_identifiers[:method].blank?
      
        parameter.export_model      = export_identifiers[:model].to_s
        parameter.export_method     = export_identifiers[:method].to_s
      end
      
      if parameter.new_record? 
        notification_message "creating parameter ..."
        parameter.created_at = Time.now
      else 
        notification_message "updating parameter ..."
        parameter.updated_at = Time.now
      end
      
      error_message "parameter could not be saved: #{parameter.errors.full_messages}", parameter_name unless parameter.save
      notification_message 'parameter saved'
      parameter
    end
      
    def parse_parameter_value(parameter, hash)
      error_message 'parameter value definition was not provided' if hash.blank?
      search_value = hash[:search_value]
      error_message 'parameter value search_value cannot be blank' if search_value.nil?      
      find_or_create_parameter_value(parameter, search_value, hash[:name])     
    end
      
    def load_parameter_value_from_source(parameter, hash)
      error_message 'parameter value definition was not provided' if hash.blank?
      
      model_name  = hash[:model]
      method_name = hash[:method]
      error_message "model and method must be defined for parameter source" if model_name.blank? || method_name.blank?
      
      source_model = model_name.safe_constantize
      error_message "model '#{model_name}' could not be found" if source_model.blank?
      
      if source_model.respond_to?(method_name)
        notification_message "method '#{method_name}' recognized as a class method"
        
        search_values = source_model.send(method_name)
        error_message "method '#{method_name}' did not return an array of values" if search_values.blank? || !search_values.kind_of?(Array)
        
        search_values.map{|search_value| find_or_create_parameter_value(parameter, search_value) }
      else
        notification_message "method '#{method_name}' is not recognized as a class method, will try it on instance.."
        error_message "model '#{model_name}' does no respond to :all method" if !source_model.respond_to?(:all)
        
        search_value_sources = source_model.send(:all)
        error_message "model '#{method_name}' did not return an array of instances" if search_value_sources.blank?
        
        search_value_sources.each do |row|
          error_message "model '#{model_name}' instanse does no respond to #{method_name} method" if !row.respond_to?(method_name)
          find_or_create_parameter_value(parameter, row.send(method_name))
        end
      end
    end
    
    def parse_operators(str)
       hash_from_file = YAML.load(str)
       
       operators_from_file = hash_from_file[:operators]
       error_message 'No operators detected in the file.' if operators_from_file.blank?
       
       Discerner::Operator.transaction do
         operators_from_file.each do |operator_from_file|
           error_message 'unique identifier has to be defined' if operator_from_file[:unique_identifier].blank?
           
           operator = Discerner::Operator.find_or_initialize_by_unique_identifier(operator_from_file[:unique_identifier])
           if operator.new_record? 
             notification_message "creating operator '#{operator_from_file[:unique_identifier]}'"
             operator.created_at = Time.now
           else 
             notification_message "operator '#{operator_from_file[:unique_identifier]}' already exists and will be updated"
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
           operator.symbol = operator_from_file[:symbol]
           operator.text = operator_from_file[:text]
           operator.binary  = operator_from_file[:binary]
           operator.deleted_at = operator_from_file[:deleted].blank? ? nil : Time.now
           error_message 'Operator could not be saved:' unless operator.save
         end
      end
    end
    
    def find_or_initialize_parameter_type(name)
      error_message "Parameter type name has to be provided" if name.blank?
      error_message "'integer' parameter type has been replaced with 'numeric', please update your dictionary definition" if /integer/.match(name.downcase)
      
      ## find or initialize parameter type
      parameter_type = Discerner::ParameterType.find_or_initialize_by_name(name.downcase)
      if parameter_type.new_record? 
        notification_message "Creating parameter type '#{name}'"
        parameter_type.created_at = Time.now
      else 
        notification_message "Parameter type '#{name}' already exists"
      end
      error_message "Parameter type #{name} could not be saved: #{parameter_type.errors.full_messages}" unless parameter_type.save
      return parameter_type
    end
    
    def find_or_create_parameter_value(parameter, search_value, name=nil)
      error_message "search value was not provided" if search_value.nil?
      search_value = search_value.to_s
      notification_message "processing parameter value '#{search_value}'"
      
      parameter_value = Discerner::ParameterValue.where(:search_value => search_value, :parameter_id => parameter.id).first_or_initialize
      if parameter_value.new_record? 
        notification_message "creating parameter value ..."
        parameter_value.created_at = Time.now
      else 
        notification_message "updating parameter value ..."
        parameter_value.updated_at = Time.now
      end
      
      parameter_value.name = name || search_value
      error_message "Parameter value #{search_value} could not be saved: #{parameter_value.errors.full_messages}" unless parameter_value.save
      notification_message 'parameter value saved'
      parameter_value
    end
    
    def error_message(str, target=nil)
      errors << "#{target}: #{str}"
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
