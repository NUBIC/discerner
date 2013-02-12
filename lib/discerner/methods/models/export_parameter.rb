module Discerner
  module Methods
    module Models
      module ExportParameter
        def self.included(base)
          # Associations
          base.send :belongs_to, :parameter
          base.send :belongs_to, :search

          # Whitelisting attributes
          base.send :attr_accessible, :parameter_id, :search_id
        end
        
        # Instance Methods
        def initialize(*args)
          super(*args)
        end
      end
    end
  end
end