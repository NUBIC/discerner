module Discerner
  module Methods
    module Models
      module Parameter
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to,  :parameter_category
          base.send :belongs_to,  :parameter_type
          base.send :has_many,    :parameter_values,   :dependent => :destroy
          base.send :has_many,    :search_parameters,  :dependent => :destroy
          base.send :has_many,    :export_parameters,  :dependent => :destroy

          # Scopes
          base.send(:scope, :searchable, -> {base.not_deleted.where('search_model is not null and search_method is not null')})
          base.send(:scope, :exportable, -> {base.not_deleted.where('export_model is not null and export_method is not null')})

          #Validations
          base.send :validates, :name, :unique_identifier, :parameter_category, :presence => true
          base.send :validate,  :validate_unique_identifier
          base.send :validate,  :validate_search_attributes
          base.send :validate,  :validate_export_attributes

          # Hooks
          base.send :after_commit, :update_parameter_values, :on => :update, :if => Proc.new { |record| record.previous_changes.include?('deleted_at') }
        end

        # Instance Methods
        def initialize(*args)
          super(*args)
        end

        def used_in_search?
          search_parameters.any? || export_parameters.any?
        end

        private
          def validate_search_parameters
            errors.add(:base,"Search should have at least one search criteria.") if
              self.search_parameters.size < 1 || self.search_parameters.all?{|search_parameter| search_parameter.marked_for_destruction? }
          end

          def validate_unique_identifier
            return if self.parameter_category.blank?
            existing_parameters =  Discerner::Parameter.
              joins({ :parameter_category => :dictionary }).
              where('discerner_dictionaries.id = ? and discerner_parameters.unique_identifier = ?', self.parameter_category.dictionary.id, self.unique_identifier)
            existing_parameters = existing_parameters.where('discerner_parameters.id != ?', self.id) unless self.id.blank?
            errors.add(:base,"Unique identifier has to be unique within dictionary.") if existing_parameters.any?
          end

          def validate_search_attributes
            unless self.search_model.blank? && self.search_method.blank?
              errors.add(:base,"Searchable parameter should have search model, search method and parameter_type defined.") if self.search_model.blank? || self.search_method.blank? || self.parameter_type.blank?
            end
          end

          def validate_export_attributes
            unless self.export_model.blank? && self.export_method.blank?
              errors.add(:base,"Exportable parameter should have export model and search method defined.") if self.export_model.blank? || self.export_method.blank?
            end
          end

          def update_parameter_values
            return unless deleted?
            parameter_values.each do |pv|
              pv.deleted_at = Time.now
              pv.save
            end
          end
      end
    end
  end
end
