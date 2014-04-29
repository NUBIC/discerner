module Discerner
  module Methods
    module Models
      module SoftDelete
        def self.included(base)
          attr_accessor :soft_delete
          base.send(:scope, :not_deleted, -> { base.where(:deleted_at => nil) })
        end

        def process_soft_delete
          self.deleted_at = Time.zone.now
        end

        def soft_delete=(removed)
          if (removed.is_a?(TrueClass) || removed.to_s == 't' || removed.to_s == '1')
            process_soft_delete
          end
        end

        def soft_delete
          !self.deleted_at.blank?
        end

        def soft_delete!
          process_soft_delete
          save!
        end

        def deleted?
          !deleted_at.blank?
        end
      end
    end
  end
end