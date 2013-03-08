module Discerner
  module Methods
    module Models
      module Dictionary
        def self.included(base)
          # Associations
          base.send :has_many, :parameter_categories, :dependent => :destroy
          base.send :has_many, :searches

          # Scopes
          base.send :scope, :not_deleted, base.where(:deleted_at => nil)

          #Validations
          @@validations_already_included ||= nil
          unless @@validations_already_included
            base.send :validates, :name, :presence => true, :uniqueness => {:message => "for dictionary has already been taken"}
            @@validations_already_included = true
          end

          # Whitelisting attributes
          base.send :attr_accessible, :name, :deleted_at

          # Hooks
          base.send :after_commit, :update_parameter_categories, :on => :update, :if => Proc.new { |record| record.previous_changes.include?('deleted_at') }
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
        end

        def deleted?
          not deleted_at.blank?
        end

        def css_class_name
          "dictionary_#{parameterized_name}"
        end

        def parameterized_name
          name.parameterize.underscore
        end

        def searchable_categories
          parameter_categories.searchable
        end

        def exportable_categories
          parameter_categories.exportable
        end

        private
          def update_parameter_categories
            return unless deleted?
            parameter_categories.each do |pc|
              pc.deleted_at = Time.now
              pc.save
            end
          end
      end
    end
  end
end
