module Discerner
  module Methods
    module Models
      module Parameter
        def self.included(base)
          # Associations
          base.send :belongs_to, :parameter_category
          base.send :belongs_to, :parameter_type
          base.send :has_many, :parameter_values
          
          # Scopes
          base.send(:scope, :not_deleted, base.where(:deleted_at => nil))
          
          #Validations
          @@validations_already_included ||= nil
          unless @@validations_already_included
            base.send :validates, :name, :database_name, :parameter_category, :parameter_type, :presence => true
            base.send :validates, :database_name, :uniqueness => true
            @@validations_already_included = true
          end
          
          # Whitelisting attributes
          base.send :attr_accessible, :database_name, :deleted_at, :name, :parameter_category, :parameter_category_id, :parameter_type, :parameter_type_id
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
