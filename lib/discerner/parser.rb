module Discerner
  class Parser
    attr_accessor :options, :errors, :updated_dictionaries, :updated_categories, :updated_parameters, :updated_parameter_values, :blank_parameter_values

    def initialize(options={})
      self.options = options
      self.errors = []
      reset_counts
    end

    def reset_counts
      self.updated_dictionaries = []
      self.updated_categories = []
      self.updated_parameters = []
      self.updated_parameter_values = []
      self.blank_parameter_values = []
    end

    def parse_dictionaries(str)
      reset_counts
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
              blank_parameter_values << find_or_create_parameter_value(parameter, '', 'None', true)
            end
          end
        end
      end
      notification_message "cleaing up ..."
      cleanup
    end

    def parse_dictionary(hash)
      error_message 'dictionary definition was not provided' if hash.blank?

      dictionary_name = hash[:name]
      error_message 'dictionary name cannot be blank' if dictionary_name.blank?
      notification_message "processing dictionary '#{dictionary_name}'"

      dictionary = Discerner::Dictionary.find_or_initialize_by_name(dictionary_name)
      dictionary.deleted_at = nil

      if dictionary.new_record?
        notification_message "creating dictionary ..."
        dictionary.created_at = Time.now
      else
        notification_message "updating dictionary ..."
        dictionary.updated_at = Time.now
      end
      error_message "dictionary could not be saved: #{dictionary.errors.full_messages}", dictionary_name unless dictionary.save
      notification_message 'dictionary saved'
      updated_dictionaries << dictionary
      dictionary
    end

    def parse_parameter_category(dictionary, hash)
      error_message 'parameter category definition was not provided' if hash.blank?

      parameter_category_name = hash[:name]
      error_message 'parameter category name cannot be blank' if parameter_category_name.blank?
      notification_message "processing parameter category  '#{parameter_category_name}'"

      parameter_category = Discerner::ParameterCategory.where(:name => parameter_category_name, :dictionary_id => dictionary.id).first_or_initialize
      parameter_category.deleted_at = nil

      if parameter_category.new_record?
        notification_message "creating parameter category ..."
        parameter_category.created_at = Time.now
      else
        notification_message "updating parameter category ..."
        parameter_category.updated_at = Time.now
      end
      error_message "parameter category could not be saved: #{parameter_category.errors.full_messages}", parameter_category_name unless parameter_category.save
      notification_message 'parameter category saved'
      updated_categories << parameter_category
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
      parameter.deleted_at  = nil
      parameter.exclusive   = hash[:exclusive].nil? ? true : to_bool(hash[:exclusive])
      parameter.parameter_category  = parameter_category

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
      updated_parameters << parameter
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

        parameter_values = source_model.send(method_name)

        error_message "method '#{method_name}' did not return an array of values" if parameter_values.blank? || !parameter_values.kind_of?(Array)

        if parameter_values.select { |parameter_value| !parameter_value.has_key?(:name) || !parameter_value.has_key?(:search_value) }.any?
          error_message "method '#{method_name}' does not adhere to the interface"
        end

        parameter_values.map{|parameter_value| find_or_create_parameter_value(parameter, parameter_value[:search_value], parameter_value[:name]) }
      else
        notification_message "method '#{method_name}' is not recognized as a class method, will try it on instance.."
        error_message "model '#{model_name}' does no respond to :all method" if !source_model.respond_to?(:all)

        search_value_sources = source_model.send(:all)
        error_message "model '#{method_name}' did not return an array of instances" if search_value_sources.blank?

        search_value_sources.each do |row|
          error_message "model '#{model_name}' instance does no respond to #{method_name} method" if !row.respond_to?(method_name)
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
           operator.symbol        = operator_from_file[:symbol]
           operator.text          = operator_from_file[:text]
           operator.operator_type = operator_from_file[:type]
           #operator.deleted_at    = operator_from_file[:deleted].blank? ? nil : Time.now
           error_message "Operator could not be saved: #{operator.errors.full_messages}" unless operator.save
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

    def find_or_create_parameter_value(parameter, search_value, name=nil, silent=nil)
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
      parameter_value.deleted_at = nil
      error_message "parameter value #{search_value} could not be saved: #{parameter_value.errors.full_messages}" unless parameter_value.save
      notification_message 'parameter value saved'
      updated_parameter_values << parameter_value unless silent
      parameter_value
    end

    def error_message(str, target=nil)
      errors << "#{target}: #{str}"
      puts "ERROR: #{str}" unless self.options[:trace].blank?
      reset_counts
      raise ActiveRecord::Rollback
    end

    def notification_message(str)
      puts str unless self.options[:trace].blank?
    end

    def to_bool(s)
      return true if s == true || s =~ (/^(true|t|yes|y|1)$/i)
      return false if s == false || s.blank? || s =~ (/^(false|f|no|n|0)$/i)
      error_message("invalid value for Boolean: \"#{s}\"")
    end

    def deleted?(param)
      return false if param.blank?
      to_bool(param)
    end

    private
      def cleanup
        cleanup_parameter_values
        cleanup_parameters
        cleanup_categories
        cleanup_dictionaries
      end

      def cleanup_dictionaries
        abandoned_dictionaries  = Discerner::Dictionary.all - updated_dictionaries
        used_dictionaries       = abandoned_dictionaries.reject{|d| d.searches.blank?}
        not_used_dictionaries   = abandoned_dictionaries - used_dictionaries

        used_dictionaries.each do |r|
          notification_message("marking dictionary #{r.name} as deleted");
          r.deleted_at = Time.now
          error_message "dictionary could not be updated: #{r.errors.full_messages}", r.name unless r.save
        end

        unless not_used_dictionaries.blank?
          notification_message("permanently deleting dictionaries #{not_used_dictionaries.map{|r| r.name}.join(', ')}");
          not_used_dictionaries.each{|r| r.destroy}
        end
      end

      def cleanup_categories
        abandoned_categories = Discerner::ParameterCategory.all - updated_categories
        used_categories      = abandoned_categories.reject{|c| c.parameters.blank? || c.parameters.select{|p| p.used_in_search?}.blank?}
        not_used_categories  = abandoned_categories - used_categories

        used_categories.each do |r|
          notification_message("marking parameter category #{r.name} as deleted");
          r.deleted_at = Time.now
          error_message "parameter category could not be deleted: #{r.errors.full_messages}", r.name unless r.save
        end

        unless not_used_categories.blank?
          notification_message("permanently deleting parameter categories #{not_used_categories.map{|r| r.name}.join(', ')}");
          not_used_categories.each{|r| r.destroy}
        end
      end

      def cleanup_parameters
        abandoned_parameters = Discerner::Parameter.all - updated_parameters
        used_parameters      = abandoned_parameters.select{|p| p.used_in_search?}
        not_used_parameters  = abandoned_parameters - used_parameters

        used_parameters.each do |r|
          notification_message("marking parameter #{r.name} as deleted");
          r.deleted_at = Time.now
          error_message "parameter could not be deleted: #{r.errors.full_messages}", r.name unless r.save
        end

        unless not_used_parameters.blank?
          notification_message("permanently deleting parameters #{not_used_parameters.map{|r| r.name}.join(', ')}");
          not_used_parameters.each{|r| r.destroy}
        end
      end

      # this also marks search_parameter_values that reference this value and are chosen as deleted
      # and destroys search_parameter_values that reference this value but are not chosen (list options)
      def cleanup_parameter_values
        abandoned_parameter_values = Discerner::ParameterValue.all - updated_parameter_values - blank_parameter_values
        used_parameter_values      = abandoned_parameter_values.select{|p| p.used_in_search?}
        not_used_parameter_values  = abandoned_parameter_values - used_parameter_values

        used_parameter_values.each do |r|
          notification_message("marking parameter value #{r.name} as deleted");
          r.deleted_at = Time.now
          error_message "parameter value could not be marked as deleted: #{r.errors.full_messages}", r.name unless r.save
        end

        unless not_used_parameter_values.blank?
          notification_message("permanently deleting parameter values #{not_used_parameter_values.map{|r| r.name}.join(', ')}");
          not_used_parameter_values.each{|r| r.destroy}
        end
      end
  end
end
