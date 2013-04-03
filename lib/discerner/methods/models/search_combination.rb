module Discerner
  module Methods
    module Models
      module SearchCombination
        def self.included(base)
          # Associations
          base.send :belongs_to, :search, :foreign_key => :search_id
          base.send :belongs_to, :combined_search, :foreign_key => :combined_search_id, :class_name => 'Discerner::Search'
          base.send :belongs_to, :operator

          # Scopes
          base.send(:scope, :not_deleted, base.where(:deleted_at => nil))

          # Validations
          @@validations_already_included ||= nil
          unless @@validations_already_included
            base.send :validate, :validate_searches
            base.send :validates, :combined_search_id, :presence => true
            @@validations_already_included = true
          end

          # Whitelisting attributes
          base.send :attr_accessible, :combined_search_id, :display_order, :operator_id, :search_id, :search, :combined_search
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
        end

        def deleted?
          not deleted_at.blank?
        end

        def warnings
          @warnings ||= ActiveModel::Errors.new(self)
        end

        def validate_searches
          return if self.search_id.blank? || self.combined_search_id.blank?
          errors.add(:base,"Search cannot be combined with itself.") if self.search_id == self.combined_search_id
        end

        def disabled?
          return false unless persisted?
          return true if deleted?
          if combined_search.deleted?
            warnings.add(:base, "Combined search has been deleted and has to be removed from the search")
            return true
          elsif combined_search.disabled?
            warnings.add(:base, "Combined search has been disabled and has to be removed from the search")
            return true
          end
          return false
        end
      end
    end
  end
end