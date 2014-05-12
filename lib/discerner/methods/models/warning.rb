module Discerner
  module Methods
    module Models
      module Warning
        def self.included(base)
          attr_accessor :force_save
        end

        def warnings
          @warnings ||= ActiveModel::Errors.new(self)
        end
      end
    end
  end
end