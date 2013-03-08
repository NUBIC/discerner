module Discerner
  module Methods
    module Models
      module SearchParameterValue
        def self.included(base)
          # Associations
          base.send :belongs_to, :search_parameter
          base.send :belongs_to, :parameter_value
          base.send :belongs_to, :operator

          # Scopes
          base.send(:scope, :not_deleted, base.where(:deleted_at => nil))
          base.send :scope, :chosen, base.where(:chosen => true)

          # Whitelisting attributes
          base.send :attr_accessible, :additional_value, :chosen, :display_order, :operator_id,
          :parameter_value_id, :search_parameter_id, :value, :parameter_value, :operator

          # Hooks
          base.send :after_commit, :destroy_if_deleted_parameter_value, :on => :update
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
        end

        def deleted?
          not deleted_at.blank?
        end

        def to_sql
          sql = {}
          raise "Search operator has to be defined in order to run 'to_sql' method on search_parameter_value" if operator.blank?
          case operator.text
            when 'is less than', 'is not equal to', 'is greater than', 'is equal to'
              sql[:predicates] = "#{search_parameter.parameter.search_method} #{operator.symbol} ?"
              sql[:values]    = formatted_values.first
            when 'is in the range'
              sql[:predicates] = "#{search_parameter.parameter.search_method} #{operator.symbol} ? and ?"
              sql[:values]    = formatted_values
            when 'is like', 'is not like'
              sql[:predicates] = "#{search_parameter.parameter.search_method} #{operator.symbol} ?"
              sql[:values]    = "%#{formatted_values.first}%"
            end
          sql
        end

        def formatted_values
          all_values = [value, additional_value].compact
          case search_parameter.parameter.parameter_type.name
          when 'date'
            all_values.map{|v| v.to_date}
          when 'numeric'
            all_values.map{|v| v.to_f}
          else
            all_values
          end
        end

        def disabled?
          return false unless persisted?
          return true if parameter_value.blank? && value.blank?
          return true if chosen? && (parameter_value.blank? || parameter_value.deleted?)
          return false
        end

        private
          def destroy_if_deleted_parameter_value
            return if parameter_value.blank? || search_parameter.blank? || search_parameter.parameter.blank? || search_parameter.parameter.parameter_type.blank?
            return unless ['list', 'combobox'].include?(search_parameter.parameter.parameter_type.name)
            destroy if parameter_value.deleted? && !chosen?
          end
      end
    end
  end
end