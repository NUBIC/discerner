module Discerner
  module Methods
    module Models
      module ParameterCategory
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to,  :dictionary, :inverse_of => :parameter_categories
          base.send :has_many,    :parameters, :inverse_of => :parameter_category,  :dependent => :destroy

          # Validations
          base.send :validates, :name, :presence => true, :uniqueness => { :scope => :dictionary_id, :message => "for parameter category has already been taken"}
          base.send :validates, :dictionary, :presence => { :message => "for parameter category can't be blank" }

          # Scopes
          base.send(:scope, :searchable, -> {base.includes(:parameters).where('discerner_parameters.search_model is not null and discerner_parameters.search_method is not null and discerner_parameters.deleted_at is null')})
          base.send(:scope, :exportable, -> {base.includes(:parameters).where('discerner_parameters.export_model is not null and discerner_parameters.export_method is not null and discerner_parameters.deleted_at is null')})
          base.send(:scope, :ordered_by_name, -> {base.order('discerner_parameter_categories.name ASC')})

          # Hooks
          base.send :after_commit, :cascade_delete_parameters, :on => :update, :if => Proc.new { |record| record.previous_changes.include?('deleted_at') }

          # Whitelisting attributes
          base.send :attr_accessible, :deleted_at, :dictionary, :dictionary_id, :name
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
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

        def css_class_name
          "parameter_category_#{parameterized_name}"
        end

        private
          def cascade_delete_parameters
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