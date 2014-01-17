module Discerner
  module Methods
    module Models
      module ExportParameter
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :parameter
          base.send :belongs_to, :search
          # Whitelisting attributes
          #base.send :attr_accessible, :parameter_id, :search_id
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