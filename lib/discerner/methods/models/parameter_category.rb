module Discerner
  module Methods
    module Models
      module ParameterCategory
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :dictionary

          # Scopes
          base.send(:scope, :searchable, -> {base.includes(:parameters).where('discerner_parameters.search_model is not null and discerner_parameters.search_method is not null and discerner_parameters.deleted_at is null').references(:discerner_parameters)})
          base.send(:scope, :exportable, -> {base.includes(:parameters).where('discerner_parameters.export_model is not null and discerner_parameters.export_method is not null and discerner_parameters.deleted_at is null').references(:discerner_parameters)})

          base.send :has_many, :parameters, :dependent => :destroy

          #Validations
          base.send :validates, :name, :presence => true, :uniqueness => { :scope => :dictionary_id, :message => "for parameter category has already been taken"}
          base.send :validates, :dictionary, :presence => { :message => "for parameter category can't be blank" }

          # Hooks
          base.send :after_commit, :update_parameters, :on => :update, :if => Proc.new { |record| record.previous_changes.include?('deleted_at') }
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