module Discerner
  module Methods
    module Models
      module ParameterType
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :has_many, :parameters
          base.send :has_and_belongs_to_many, :operators, :join_table => :discerner_operators_parameter_types

          #Validations
          @@validations_already_included ||= nil
          unless @@validations_already_included
            base.send :validates, :name, :presence => true, :uniqueness => {:message => "for parameter type has already been taken"}
            base.send :validate, :name_supported?
            @@validations_already_included = true
          end

          # Whitelisting attributes
          base.send :attr_accessible, :deleted_at, :name
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
        end

        def name_supported?
          return if self.name.blank?
          supported_types = ['numeric', 'date', 'list', 'combobox', 'text', 'string', 'search']
          errors.add(:base,"Parameter type '#{self.name}' is not supported, please use one of the following types: #{supported_types.join(', ')}") unless supported_types.include?(self.name)
        end
      end
    end
  end
end