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
          base.send :scope, :chosen, base.where(:chosen => true)
          
          # Whitelisting attributes
          base.send :attr_accessible, :additional_value, :chosen, :display_order, :operator_id, 
          :parameter_value_id, :search_parameter_id, :value, :parameter_value, :operator
        end
        
        # Instance Methods
        def initialize(*args)
          super(*args)
        end
      end
    end
  end
end