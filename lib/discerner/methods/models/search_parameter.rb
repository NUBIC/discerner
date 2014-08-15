module Discerner
  module Methods
    module Models
      module SearchParameter
        def self.included(base)
          base.send :include, SoftDelete
          base.send :include, Warning

          # Associations
          base.send :belongs_to,  :search,     :inverse_of => :search_parameters
          base.send :belongs_to,  :parameter,  :inverse_of => :search_parameters
          base.send :has_many,    :search_parameter_values, :dependent => :destroy, :inverse_of => :search_parameter

          # Scopes
          base.send(:scope, :by_parameter_category, ->(parameter_category) { base.includes(:parameter).where('discerner_parameters.parameter_category_id' => parameter_category.id) unless parameter_category.blank?})
          base.send(:scope, :ordered_by_display_order, -> { base.order('discerner_search_parameters.display_order ASC') })
          base.send(:scope, :ordered, -> { base.order('discerner_search_parameters.id ASC') })

          #Validations
          base.send :validates_presence_of, :search, :parameter

          # Nested attributes
          base.send :accepts_nested_attributes_for, :search_parameter_values, :allow_destroy => true

          # Hooks
          base.send :after_commit, :update_associations, :on => :update, :if => Proc.new { |record| record.previous_changes.include?('deleted_at') }
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
        end

        def check_search_parameters
          if self.search_parameters.size < 1 || self.search_parameters.all?{|search_parameter| search_parameter.marked_for_destruction? }
            errors.add(:base,"Search should have at least one search criteria.")
          end
        end

        def parameterized_name
          name.blank? ? 'no_name_specified' : name.parameterize.underscore
        end

        def prepare_sql
          sql = {}
          parameter_type = parameter.parameter_type.name
          case parameter_type
          when 'list'
            values    = [search_parameter_values.chosen.map { |spv| spv.parameter_value.search_value }]
            predicate = "#{parameter.search_method} in (?)"
          when 'combobox'
            values    = [search_parameter_values.map { |spv| spv.parameter_value.search_value unless spv.parameter_value.nil? }.compact]
            predicate = "#{parameter.search_method} in (?)" unless values.blank?
          else # 'numeric','date', 'text', 'string
            spvs = []
            values = []
            search_parameter_values.map {|spv| spvs << spv.to_sql}

            predicates = spvs.map { |s| s[:predicates] }.join(' or ')
            predicate = "(#{predicates})"

            spvs.each do |spv|
              if spv[:values].is_a?(Array)
                spv[:values].each do |v|
                  values << v
                end
              else
                values << spv[:values] unless spv[:values].blank?
              end
            end
          end
          sql[:predicates] = predicate
          sql[:values] = values
          sql
        end

        def search_model_class
          return if parameter.search_model.blank? || parameter.search_method.blank?
          search_model_class = parameter.search_model.safe_constantize
          raise "Search model #{parameter.search_model} could not be found" if search_model_class.blank?
          search_model_class
        end

        def search_model_attribute_method?
          search_model_class && search_model_class.attribute_method?(parameter.search_method)
        end

        def to_sql
          sql = prepare_sql
          if search_model_class && !search_model_attribute_method?
            raise "Search model #{parameter.search_model} does not respond to search method #{parameter.search_method}" unless search_model_class.respond_to?(parameter.search_method)
            sql = search_model_class.send(parameter.search_method, sql)
          end
          sql
        end

        def disabled?
          return false unless persisted?
          if parameter.blank?
            warnings.add(:base, "Parameter has to be selected")
            return true
          elsif parameter.deleted?
            warnings.add(:base, "Parameter has been deleted and has to be removed from the search")
            return true
          elsif search_parameter_values.blank? || (parameter.parameter_type.name == 'list' && search_parameter_values.select{|spv| spv.chosen?}.empty?)
            warnings.add(:base, "Parameter value has to be selected")
            return true
          elsif deleted? || search_parameter_values.select{ |spv| spv.disabled?}.any?
            return true
          end
        end



        private
          def update_associations
            search_parameter_values.each do |r|
              r.deleted_at = Time.now
              r.save
            end
          end
      end
    end
  end
end