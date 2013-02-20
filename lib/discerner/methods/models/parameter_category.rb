module Discerner
  module Methods
    module Models
      module ParameterCategory
        def self.included(base)
          # Associations
          base.send :belongs_to, :dictionary
          base.send :has_many, :parameters
          
          # Scopes
          base.send(:scope, :not_deleted, base.where(:deleted_at => nil))
          base.send(:scope, :searchable, base.includes(:parameters).where('discerner_parameters.searchable' => true))
          
          #Validations
          @@validations_already_included ||= nil
          unless @@validations_already_included
            base.send :validates, :name, :presence => true, :uniqueness => { :scope => :dictionary_id, :message => "for parameter category has already been taken"}
            base.send :validates, :dictionary, :presence => { :message => "for parameter category can't be blank" }
            @@validations_already_included = true
          end
          
          # Whitelisting attributes
          base.send :attr_accessible, :deleted_at, :dictionary, :dictionary_id, :name
        end
        
        # Instance Methods
        def initialize(*args)
          super(*args)
        end
        
        def deleted?
          not deleted_at.blank?
        end
        
        def parameterized_name
          name.parameterize.underscore
        end
        
        def searchable_parameters
          parameters.searchable
        end
      end
    end
  end
end