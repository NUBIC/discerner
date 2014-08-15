module Discerner
  module Methods
    module Models
      module ParameterValue
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to,  :parameter,                       inverse_of: :parameter_values
          base.send :has_many,    :search_parameter_values,         inverse_of: :parameter_value, dependent: :destroy
          base.send :has_one,     :parameter_value_categorization,  inverse_of: :parameter_value, dependent: :destroy
          base.send :has_one,     :parameter_value_category,        :through=> :parameter_value_categorization

          # Scopes
          base.send(:scope, :ordered_by_name, -> { base.order('discerner_parameter_values.name ASC') })
          base.send(:scope, :ordered_by_parameter_and_name, -> { base.order('discerner_parameter_values.parameter_id ASC, discerner_parameter_values.name ASC') })

          #Validations
          base.send :validates, :parameter, presence: true
          base.send :validates, :search_value, length: { maximum: 1000 }, uniqueness: {scope: :parameter_id, message: "for parameter value has already been taken"}
          base.send :validates, :name, presence: true, length: { maximum: 1000 }
          base.send :validate,  :parameter_category_belongs_to_parameter

          # Hooks
          base.send :after_commit, :create_search_parameter_values, on: :create
          base.send :after_commit, :update_search_parameter_values, on: :update, if: Proc.new { |record| record.previous_changes.include?('deleted_at') }
          base.send :scope, :categorized, -> {base.joins(:parameter_value_category)}
          base.send :scope, :uncategorized, -> {base.includes(:parameter_value_category).where(discerner_parameter_value_categories: {name: nil})}
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
        end

        def used_in_search?
          if parameter.parameter_type.name == 'list'
            search_parameter_values.chosen.any?
          else
            search_parameter_values.any?
          end
        end

        def display_name
          if parameter_value_category
            "#{parameter_value_category.name} - #{name} "
          else
            name
          end
        end

        private
          def parameter_category_belongs_to_parameter
            unless parameter_value_category.blank?
              errors.add(:base,"Parameter category #{parameter_value_category.name} does not belong to parameter #{parameter.name}") unless parameter_value_category.parameter_id == parameter.id
            end
          end

          def create_search_parameter_values
            # create additional search_parameter_values for list search_parameters so they can be dislayed as nested attribures
            return if parameter.blank? || parameter.parameter_type.blank?
            if parameter.parameter_type.name == 'list'
              parameter.search_parameters.each do |sp|
                if sp.search_parameter_values.where(parameter_value_id: id).blank?
                  max_display_order = sp.search_parameter_values.ordered_by_display_order.last.display_order || -1
                  sp.search_parameter_values.build(parameter_value_id: id, display_order: max_display_order + 1)
                  sp.save
                end
              end
            end
          end

          def update_search_parameter_values
            create_search_parameter_values
            # destroy search_parameter_values that reference this value but are not chosen (list options)
            return unless deleted?
            search_parameter_values.each do |spv|
              spv.destroy if parameter.parameter_type.name == 'list' && !spv.chosen
            end
          end
      end
    end
  end
end