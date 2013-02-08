module Discerner
  module Methods
    module Models
      module Search
        def self.included(base)
          # Associations
          base.send :belongs_to, :dictionary
          base.send :has_many, :search_parameters
          base.send :has_many, :search_combinations
          base.send :has_many, :combined_searches, :through => :search_combinations
          
          # Scopes
          base.send(:scope, :not_deleted, base.where(:deleted_at => nil))
          
          # Validations
          @@validations_already_included ||= nil
          unless @@validations_already_included
            base.send :validates, :dictionary, :presence => { :message => "for search can't be blank" }
            base.send :validate, :validate_search_parameters
            @@validations_already_included = true
          end
          
          # Nested attributes
          base.send :accepts_nested_attributes_for, :search_parameters, :allow_destroy => true,
            :reject_if => proc { |attributes| attributes['parameter_id'].blank? && attributes['parameter'].blank? }

          # Nested attributes
          base.send :accepts_nested_attributes_for, :search_combinations, :allow_destroy => true,
            :reject_if => proc { |attributes| attributes['combined_search_id'].blank? && attributes['combined_search'].blank? }
          
          # Whitelisting attributes
          base.send :attr_accessible, :deleted_at, :name, :username, :search_parameters, :search_parameters_attributes, 
          :dictionary, :dictionary_id, :search_combinations_attributes
        end
        
        # Instance Methods
        def initialize(*args)
          super(*args)
        end
        
        def deleted?
          not deleted_at.blank?
        end
        
        def validate_search_parameters
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