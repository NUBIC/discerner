module Discerner
  module Methods
    module Models
      module ParameterType
        def self.included(base)
          # Associations
          base.send :has_many, :parameters
          base.send :has_and_belongs_to_many, :operators, :join_table => :discerner_operators_parameter_types
          
          # Scopes
          base.send(:scope, :not_deleted, base.where(:deleted_at => nil))
          
          #Validations
          @@validations_already_included ||= nil
          unless @@validations_already_included
            base.send :validates, :name, :presence => true, :uniqueness => {:message => "for parameter type has already been taken"}
            @@validations_already_included = true
          end
          
          # Whitelisting attributes
          base.send :attr_accessible, :deleted_at, :name
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