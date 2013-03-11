module Discerner
  module Methods
    module Models
      module ParameterValue
        def self.included(base)
          # Associations
          base.send :belongs_to, :parameter
          base.send :has_many, :search_parameter_values, :dependent => :destroy

          # Scopes
          base.send(:scope, :not_deleted, base.where(:deleted_at => nil))

          #Validations
          @@validations_already_included ||= nil
          unless @@validations_already_included
            base.send :validates, :parameter, :presence => true
            base.send :validates, :search_value, :length => { :maximum => 1000 }, :uniqueness => {:scope => :parameter_id, :message => "for parameter value has already been taken"}
            base.send :validates, :name, :presence => true, :length => { :maximum => 1000 }
            @@validations_already_included = true
          end

          # Whitelisting attributes
          base.send :attr_accessible, :search_value, :name, :parameter, :parameter_id

          # Hooks
          base.send :after_commit, :create_search_parameter_values, :on => :create
          base.send :after_commit, :update_search_parameter_values, :on => :update, :if => Proc.new { |record| record.previous_changes.include?('deleted_at') }
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
        end

        def deleted?
          not deleted_at.blank?
        end

        def used_in_search?
          search_parameter_values.chosen.any?
        end

        private
          def create_search_parameter_values
            # create additional search_parameter_values for list and combobox search_parameters
            return if parameter.blank? || parameter.parameter_type.blank?
            return unless ['list', 'combobox'].include?(parameter.parameter_type.name)
            parameter.search_parameters.each do |sp|
              if sp.search_parameter_values.where(:parameter_value_id => id).blank?
                max_display_order = sp.search_parameter_values.order(:display_order).last.display_order || -1
                sp.search_parameter_values.build(:parameter_value_id => id, :display_order => max_display_order + 1)
                sp.save
              end
            end
          end

          def update_search_parameter_values
            create_search_parameter_values
            # destroy search_parameter_values that reference this value but are not chosen (list options)
            return unless deleted?
            search_parameter_values.each do |spv|
              spv.destroy unless spv.chosen
            end
          end
      end
    end
  end
end