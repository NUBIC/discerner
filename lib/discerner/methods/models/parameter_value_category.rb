module Discerner
  module Methods
    module Models
      module ParameterValueCategory
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :parameter
          base.send :has_many, :parameter_value_categorizations
          base.send :has_many, :parameter_values, :through => :parameter_value_categorizations

          # Validations
          base.send :validates_presence_of, :parameter, :unique_identifier, :name
          base.send :validates, :unique_identifier, :uniqueness => {:scope => [:parameter_id, :deleted_at], :message => "for parameter value category has already been taken"}
          base.send :validate, :parameter_value_belongs_to_parameter
        end

        private
          def parameter_value_belongs_to_parameter
            unless parameter.blank?
              parameter_values.each do |parameter_value|
                errors.add(:base,"Parameter value #{parameter_value.name} does not belong to parameter #{parameter.name}") unless parameter_value.parameter_id == parameter.id
              end
            end
          end
      end
    end
  end
end