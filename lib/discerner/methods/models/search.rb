module Discerner
  module Methods
    module Models
      module Search
        def self.included(base)
          base.send :include, SoftDelete
          base.send :include, Warning

          # Associations
          base.send :belongs_to, :dictionary
          base.send :has_many, :search_parameters
          base.send :has_many, :search_combinations
          base.send :has_many, :combined_searches, :through => :search_combinations
          base.send :has_many, :export_parameters

          # Scopes
          base.send(:scope, :by_user, ->(username) { base.where(:username => username) unless username.blank?})

          # Validations
          base.send :validates, :dictionary, :presence => { :message => "for search can't be blank" }
          base.send :validate, :validate_search_parameters

          # Nested attributes
          base.send :accepts_nested_attributes_for, :search_parameters, :allow_destroy => true,
            :reject_if => proc { |attributes| attributes['parameter_id'].blank? && attributes['parameter'].blank? }

          base.send :accepts_nested_attributes_for, :search_combinations, :allow_destroy => true,
            :reject_if => proc { |attributes| attributes['combined_search_id'].blank? && attributes['combined_search'].blank? }

          # Hooks
          base.send :after_commit, :update_associations, :on => :update, :if => Proc.new { |record| record.previous_changes.include?('deleted_at') }

          # Whitelisting attributes
          base.send :attr_accessible, :deleted_at, :name, :username, :search_parameters, :search_parameters_attributes,
          :dictionary, :dictionary_id, :search_combinations_attributes

        end

        # Instance Methods
        def initialize(*args)
          super(*args)
        end

        def display_name
          name.blank? ? "[No name specified]" : name
        end

        def parameterized_name
          display_name.parameterize.underscore
        end

        def traverse
          return unless combined_searches.any?
          searches = []
          combined_searches.each do |s|
            searches << s
            nested_searches = s.traverse
            searches << nested_searches unless nested_searches.blank?
          end
          searches
        end

        def nested_searches
          nested_searches = traverse || []
          nested_searches.flatten.compact
        end

        def parameter_categories
          search_parameters.map{|p| p.parameter.parameter_category unless p.parameter.blank?}.uniq
        end

        def to_conditions
          search_models = {}
          all_search_parameters = nested_searches.map { |ns| ns.search_parameters }.flatten
          all_search_parameters.concat(search_parameters).flatten!

          all_search_parameters.each do |search_parameter|
            search_models[search_parameter.parameter.search_model] = { :search_parameters => [], :conditions => nil } unless search_models.has_key?(search_parameter.parameter.search_model)
            search_models[search_parameter.parameter.search_model][:search_parameters] << search_parameter
          end

          search_models.each do |k,v|
            predicates = []
            arguments = []

            v[:search_parameters].each do |search_parameter|
              sql = search_parameter.to_sql unless search_parameter.search_parameter_values.empty?
              unless sql.nil?
                predicates << sql[:predicates]
                arguments << sql[:values] unless sql[:values].blank?
              end
            end

            search_models[k][:conditions] = [predicates.join(' and '), *flatten_arguments(arguments)]
          end
          search_models
        end

        def flatten_arguments(arguments)
          args = []
          arguments.each do |a|
            a.each do |b|
              args << b
            end
          end
          args
        end

        def disabled?
          return false unless persisted?
          if export_parameters.select{|ep| ep.disabled?}.any?
            warnings.add(:base, "Search uses deleted export parameters")
            return true
          end
          deleted? ||
          dictionary.deleted? ||
          search_parameters.select{|sp| sp.disabled?}.any? ||
          search_combinations.select{|sc| sc.disabled?}.any?
        end

        def searched_model?(model_name)
          conditions.has_key?(model_name)
        end

        def conditions(force=false)
          @conditions = self.to_conditions if @conditions.blank? || force
          @conditions
        end

        private
          def validate_search_parameters
            if self.search_parameters.size < 1 || self.search_parameters.all?{|search_parameter| search_parameter.marked_for_destruction? }
              errors.add(:base,"Search should have at least one search criteria.")
            end
          end

          def update_associations
            [search_parameters, export_parameters, search_combinations].each do |accociated_records|
              accociated_records.each do |r|
                r.deleted_at = Time.now
                r.save
              end
            end
          end
      end
    end
  end
end