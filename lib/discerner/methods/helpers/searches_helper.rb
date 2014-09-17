module Discerner
  module Methods
    module Helpers
      module SearchesHelper
        def discerner_results_partial
          "discerner/dictionaries/#{@discerner_search.dictionary.parameterized_name}/results"
        end

        def discerner_generate_nested_attributes_template(f, association, association_prefix = nil )
          if association_prefix.nil?
            association_prefix = association.to_s.singularize
          end
          new_object = f.object.class.reflect_on_association(association).klass.new
          fields = f.fields_for(association, new_object, child_index: "new_#{association}") do |form_builder|
            render(association_prefix + "_fields", f: form_builder)
          end
          escape_javascript(fields)
        end

        def discerner_link_to_add_fields(name, association, html_options={})
          css_class = html_options[:class] || ' '
          css_class += "add_#{association.to_s} add discerner-add-link discerner-icon-link"
          html_options[:class] = css_class
          link_to(name, 'javascript:void(0);', html_options)
        end

        def discerner_link_to_remove_fields(name, f, association)
          f.hidden_field(:_destroy) + link_to(name, "javascript:void(0);", class: "delete_#{association.to_s} discerner-delete-link discerner-icon-link")
        end

        def discerner_nested_record_id(builder, assocation)
          builder.object.id.nil? ? "new_nested_record" : "#{assocation.to_s.singularize}_#{builder.object.id}"
        end

        def operator_options(type=nil)
          operators = Discerner::Operator.not_deleted
          unless type.blank?
            operators = operators.joins(:parameter_types).where("discerner_parameter_types.name in (?)", type)
          end
          operators.includes(:parameter_types).uniq.map {|o| [o.text, o.id, {class: o.css_class_name}]}
        end

        def dictionary_options(searchable_dictionaries)
          searchable_dictionaries.map{|d| [d.name, d.id, {class: d.css_class_name}]}
        end

        def combined_searches_options(search=nil)
          all_searches = Discerner::Search.order(:id)

          username = discerner_user.username unless discerner_user.blank?
          all_searches = all_searches.by_user(username) unless username.blank?

          if search.blank? || !search.persisted?
            searches = all_searches.not_deleted.reject{|s| s.disabled?}
          else
            searches_available = all_searches.not_deleted.
              where('id != ? and dictionary_id = ?', search.id,search.dictionary_id).
              reject{|s| s.nested_searches.include?(search) || s.disabled?}
            searches_used = search.combined_searches
            searches = searches_available | searches_used
          end
          searches.map {|s| [s.display_name, s.id, {class: s.dictionary.css_class_name}]}
        end

        def parameter_options(searchable_parameters, base_id=nil)
          options = []
          searchable_parameters.each do |p|
            option = [p.display_name, p.id]
            html_options = {class: p.css_class_name}
            html_options[:id] = searchable_object_index(p, base_id) unless base_id.blank?
            option << html_options
            options << option
          end
          options
        end

        def parameter_value_options(searchable_values, base_id=nil)
          options = []
          searchable_values.each do |pv|
            option = [pv.display_name, pv.id]
            html_options = {}
            html_options[:id] = searchable_object_index(pv, base_id) unless base_id.blank?
            option << html_options
            options << option
          end
          options
        end

        def searchable_object_index(object, base_id=nil)
          "#{base_id}_#{object.id}"
        end

        def exportable_parameter_categories(search=nil)
          if search.blank? || !search.persisted?
            parameter_categories = Discerner::ParameterCategory.not_deleted.exportable.to_a
          else
            parameter_categories_available = search.dictionary.parameter_categories.exportable.to_a
            parameter_categories_used      = search.export_parameters.map{ |ep| ep.parameter.parameter_category }.flatten
            parameter_categories           = parameter_categories_available | parameter_categories_used
          end
          parameter_categories.sort{|a,b| a.parameters.length <=> b.parameters.length}
        end

        def exportable_parameters(search, category)
          return if search.blank? || !search.persisted?
          parameters_available = category.parameters.exportable.to_a
          parameters_used      = search.export_parameters.map{|ep| ep.parameter}.reject{|p| p.parameter_category != category }.flatten
          parameters           = parameters_available | parameters_used
          parameters.sort{|a,b| a.name <=> b.name}
        end

        def search_parameter_values(search_parameter)
          search_parameter_values = search_parameter.parameter.parameter_type.name == 'list' ? search_parameter.search_parameter_values.chosen : search_parameter.search_parameter_values
          display_values = []
          search_parameter_values.each do |spv|
            string = ''
            value = spv.parameter_value.blank? ? spv.value : spv.parameter_value.name
            string += spv.operator.text unless spv.operator.blank?
            string += " \"#{value}\"" unless value.blank?
            string += " \"#{spv.additional_value}\"" unless spv.additional_value.blank?
            display_values << string
          end
          display_values.join(' or ')
        end

        def discerner_export_link
          link_to "Export options", export_parameters_path(@discerner_search), class: "discerner-button discerner-button-positive"
        end

        def discerner_format_datetime(datetime)
          datetime.strftime("%m/%d/%Y %I:%M %p") if datetime
        end

        def discerner_format_date(date)
          date.strftime("%m/%d/%Y") if date
        end
      end
    end
  end
end
