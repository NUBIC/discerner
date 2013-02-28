module Discerner
  module Methods
    module Models
      module ParameterValue
        def self.included(base)
          # Associations
          base.send :belongs_to, :parameter
          base.send :has_many, :search_parameter_values
          
          # Scopes
          base.send(:scope, :not_deleted, base.where(:deleted_at => nil))
          
          #Validations
          @@validations_already_included ||= nil
          unless @@validations_already_included
            base.send :validates, :parameter, :presence => true
            base.send :validates, :search_value, :presence => true, :length => { :maximum => 1000 }, :uniqueness => {:scope => :parameter_id, :message => "for parameter value has already been taken"}
            base.send :validates, :name, :presence => true, :length => { :maximum => 1000 }
            @@validations_already_included = true
          end
          
          # Whitelisting attributes
          base.send :attr_accessible, :search_value, :deleted_at, :name, :parameter, :parameter_id
        end
        
        # Instance Methods
        def initialize(*args)
          super(*args)
        end
        
        def deleted?
          not deleted_at.blank?
        end
      end
    end
  end
end