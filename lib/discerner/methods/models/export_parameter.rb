module Discerner
  module Methods
    module Models
      module ExportParameter
        def self.included(base)
          # Associations
          base.send :belongs_to, :parameter
          base.send :belongs_to, :search

          # Scopes
          base.send(:scope, :not_deleted, base.where(:deleted_at => nil))

          # Whitelisting attributes
          base.send :attr_accessible, :parameter_id, :search_id
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