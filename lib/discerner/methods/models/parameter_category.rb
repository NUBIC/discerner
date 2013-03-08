module Discerner
  module Methods
    module Models
      module ParameterCategory
        def self.included(base)
          # Associations
          base.send :belongs_to, :dictionary
          base.send :has_many, :parameters, :order => :name, :dependent => :destroy

          # Scopes
          base.send(:scope, :not_deleted, base.where(:deleted_at => nil))
          base.send(:scope, :searchable, base.includes(:parameters).where('discerner_parameters.search_model is not null and discerner_parameters.search_method is not null and discerner_parameters.deleted_at is null'))
          base.send(:scope, :exportable, base.includes(:parameters).where('discerner_parameters.export_model is not null and discerner_parameters.export_method is not null and discerner_parameters.deleted_at is null'))

          #Validations
          @@validations_already_included ||= nil
          unless @@validations_already_included
            base.send :validates, :name, :presence => true, :uniqueness => { :scope => :dictionary_id, :message => "for parameter category has already been taken"}
            base.send :validates, :dictionary, :presence => { :message => "for parameter category can't be blank" }
            @@validations_already_included = true
          end

          # Whitelisting attributes
          base.send :attr_accessible, :deleted_at, :dictionary, :dictionary_id, :name

          # Hooks
          base.send :after_commit, :update_parameters, :on => :update, :if => Proc.new { |record| record.previous_changes.include?('deleted_at') }
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
        end

        def deleted?
          not deleted_at.blank?
        end

        def parameterized_name
          name.parameterize.underscore
        end

        def searchable_parameters
          parameters.searchable
        end

        def exportable_parameters
          parameters.exportable
        end

        private
          def update_parameters
            return unless deleted?
            parameters.each do |p|
              p.deleted_at = Time.now
              p.save
            end
          end
      end
    end
  end
end