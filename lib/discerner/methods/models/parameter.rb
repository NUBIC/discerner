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
          base.send(:scope, :searchable, base.where(:searchable => true))
          
          #Validations
          @@validations_already_included ||= nil
          unless @@validations_already_included
            base.send :validates, :name, :search_model, :search_attribute, :parameter_category, :parameter_type, :presence => true
            base.send :validates, :search_attribute, :uniqueness => { :scope => [:search_model, :parameter_category_id], :message => "for parameter category and model has already been taken"}
            @@validations_already_included = true
          end
          
          # Whitelisting attributes
          base.send :attr_accessible, :deleted_at, :name, :parameter_category, :parameter_category_id, :parameter_type, :parameter_type_id, :search_model, :search_attribute
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
