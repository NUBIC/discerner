module Discerner
  module Methods
    module Models
      module Operator
        def self.included(base)
          # Associations
          base.send :has_and_belongs_to_many, :parameter_types, :join_table => :discerner_operators_parameter_types
          base.send :has_many, :search_parameter_values
          
          # Scopes
          base.send(:scope, :not_deleted, base.where(:deleted_at => nil))
          
          #Validations
          @@validations_already_included ||= nil
          unless @@validations_already_included
            base.send :validates, :symbol, :presence => true, :uniqueness => {:message => "for operator has already been taken"}
            @@validations_already_included = true
          end
          
          # Whitelisting attributes
          base.send :attr_accessible, :binary, :symbol, :text, :deleted_at
        end
        
        # Instance Methods
        def initialize(*args)
          super(*args)
        end
        
        def deleted?
          not deleted_at.blank?
        end

        def css_class_name
          css_class = parameter_types.map{ |t| t.name }.join(' ')
          css_class += ' binary' unless binary.blank?
          css_class
        end
      end
    end
  end
end
