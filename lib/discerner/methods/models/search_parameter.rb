module Discerner
  module Methods
    module Models
      module SearchParameter
        def self.included(base)
          # Associations
          base.send :belongs_to, :search
          base.send :belongs_to, :parameter
          base.send :has_many, :search_parameter_values, :dependent => :destroy
          
          # Scopes
          base.send(:scope, :by_parameter_category, lambda{|parameter_category| base.includes(:parameter).where('discerner_parameters.parameter_category_id' => parameter_category.id) unless parameter_category.blank?})
          
          # Nested attributes
          base.send :accepts_nested_attributes_for, :search_parameter_values, :allow_destroy => true
          
          # Whitelisting attributes
          base.send :attr_accessible, :display_order, :parameter_id, :search_id, :parameter, :search, :search_parameter_values_attributes
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
      end
    end
  end
end