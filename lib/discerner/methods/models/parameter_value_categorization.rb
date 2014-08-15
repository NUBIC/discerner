module Discerner
  module Methods
    module Models
      module ParameterValueCategorization
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :parameter_value_category, :inverse_of => :parameter_value_categorizations
          base.send :belongs_to, :parameter_value,          :inverse_of => :parameter_value_categorization

          # Validations
          base.send :validates_presence_of, :parameter_value_category, :parameter_value
        end
      end
    end
  end
end