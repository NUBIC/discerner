module Discerner
  module Methods
    module Models
      module ExportParameter
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :parameter,  :inverse_of => :export_parameters
          base.send :belongs_to, :search,     :inverse_of => :export_parameters

          # Scopes
          base.send(:scope, :ordered, -> { base.order('discerner_export_parameters.id ASC') })
          base.send(:scope, :by_parameter_category, ->(parameter_category) { includes(:parameter).where('discerner_parameters.parameter_category_id' => parameter_category.id) unless parameter_category.blank?})

          # Validations
          base.send :validates, :parameter, :search, :presence => { :message => "for export parameter can't be blank" }

          # Whitelisting attributes
          base.send :attr_accessible, :parameter_id, :search_id, :parameter, :search
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
        end

        def disabled?
          return false unless persisted?
          deleted? || parameter.blank? || parameter.deleted?
        end
      end
    end
  end
end