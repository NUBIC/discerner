module Discerner
  module Methods
    module Models
      module SearchCombination
        def self.included(base)
          base.send :include, SoftDelete
          base.send :include, Warning

          # Associations
          base.send :belongs_to, :operator, :inverse_of => :search_combinations
          base.send :belongs_to, :search,   :inverse_of => :search_combinations,  :foreign_key => :search_id
          base.send :belongs_to, :combined_search, :foreign_key => :combined_search_id, :class_name => 'Discerner::Search'

          # Scopes
          base.send(:scope, :ordered_by_display_order, -> { base.order('discerner_search_combinations.display_order ASC') })

          # Validations
          base.send :validates_presence_of, :search, :combined_search
          base.send :validate, :validate_searches

          # Whitelisting attributes
          base.send :attr_accessible, :combined_search_id, :display_order, :operator_id, :search_id, :search, :combined_search
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
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