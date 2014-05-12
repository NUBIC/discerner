module Discerner
  module Methods
    module Models
      module ExportParameter
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :parameter,  :inverse_of => :export_parameters
          base.send :belongs_to, :search,     :inverse_of => :export_parameters

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