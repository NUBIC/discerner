module Discerner
  module Methods
    module Models
      module SearchNamespace
        def self.included(base)
          base.send :belongs_to, :search
          base.send :belongs_to, :namespace, polymorphic: true
        end
      end
    end
  end
end