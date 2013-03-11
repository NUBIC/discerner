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
            base.send :validates, :operator_type, :presence => true
            base.send :validate,  :type_supported?
            @@validations_already_included = true
          end

          # Whitelisting attributes
          base.send :attr_accessible, :operator_type, :symbol, :text, :deleted_at
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
        end

        def deleted?
          not deleted_at.blank?
        end

        def css_class_name
          css_class = parameter_types.map{ |t| t.name }
          css_class << operator_type unless operator_type.blank?
          css_class.join(' ')
        end

        private
          def type_supported?
            return if self.operator_type.blank?
            supported_types = ['comparison', 'text_comparison', 'range', 'list', 'presence']
            errors.add(:base,"Operator type '#{self.operator_type}' is not supported, please use one of the following types: #{supported_types.join(', ')}") unless supported_types.include?(self.operator_type)
          end
      end
    end
  end
end
