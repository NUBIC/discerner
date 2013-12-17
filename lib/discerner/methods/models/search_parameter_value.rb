module Discerner
  module Methods
    module Models
      module SearchParameterValue
        def self.included(base)
          #base.send :include, Warnings
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

        def warnings
          @warnings ||= ActiveModel::Errors.new(self)
        end

        def to_sql
          sql = {}
          raise "Search operator has to be defined in order to run 'to_sql' method on search_parameter_value" if operator.blank?
          case operator.operator_type
            when 'comparison'
              sql[:predicates] = "#{search_parameter.parameter.search_method} #{operator.symbol} ?"
              sql[:values]    = formatted_values.first
            when 'range'
              sql[:predicates] = "#{search_parameter.parameter.search_method} #{operator.symbol} ? and ?"
              sql[:values]    = formatted_values
            when 'text_comparison'
              sql[:predicates] = "#{search_parameter.parameter.search_method} #{operator.symbol} ?"
              sql[:values]    = "%#{formatted_values.first}%"
            when 'presence'
              sql[:predicates] = "#{search_parameter.parameter.search_method} #{operator.symbol}"
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
          if parameter_value.blank? && value.blank? && operator && operator.operator_type != 'presence'
            warnings.add(:base, "Parameter value has to be selected")
            return true
          end
          if chosen? && parameter_value.blank? || parameter_value && parameter_value.deleted?
            warnings.add(:base, "Parameter value has been deleted and has to be removed from the search")
            return true
          end
          if search_parameter && search_parameter.parameter && search_parameter.parameter.parameter_type.name == 'date' && !validate_dates_format
            warnings.add(:base, "Provided date is not valid")
            return true
          end
          warnings.clear
          return false
        end

        def validate_dates_format
          validate_date(value) && validate_date(additional_value)
        end

        private
          def destroy_if_deleted_parameter_value
            return if parameter_value.blank? || search_parameter.blank? || search_parameter.parameter.blank? || search_parameter.parameter.parameter_type.blank?
            #return unless ['list', 'combobox'].include?(search_parameter.parameter.parameter_type.name)
            destroy if parameter_value.deleted? && search_parameter.parameter.parameter_type.name == 'list' && !chosen?
          end

          def validate_date(date)
            begin
              unless date.blank?
                parsed_date = date.to_date
                #http://www.karaszi.com/sqlserver/info_datetime.asp#Why1753
                return false if parsed_date.year < 1753
              end
            rescue => e
              return false
            end
            return true
          end
      end
    end
  end
end