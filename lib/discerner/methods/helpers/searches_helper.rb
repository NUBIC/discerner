module Discerner
  module Methods
    module Helpers
      module SearchesHelper
        def discerner_results_partial
          "discerner/dictionaries/#{@discerner_search.dictionary.parameterized_name}/results"
        end
        
        def hidden(o)
          if o.blank?
            'hidden'
          else
            ''
          end
        end

        def checked?(params, value, default)
          if params.nil? and default
            true
          else
            params == value
          end
        end

        def generate_nested_attributes_template(f, association, association_prefix = nil )
          if association_prefix.nil?
            association_prefix = association.to_s.singularize
          end
          new_object = f.object.class.reflect_on_association(association).klass.new
          fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |form_builder|
            render(association_prefix + "_fields", :f => form_builder)
          end
          escape_javascript(fields)
        end

        def link_to_add_fields(name, association, html_options={})
          css_class = html_options[:class] || ' '
          css_class += "add_#{association.to_s} add add_link icon_link"
          html_options[:class] = css_class
          link_to(name, 'javascript:void(0);', html_options)
        end

        def link_to_remove_fields(name, f, association)
          f.hidden_field(:_destroy) + link_to(name, "javascript:void(0);", :class => "delete_#{association.to_s} delete_link icon_link")
        end

        def link_to_soft_delete_fields(name, f, association)
          f.hidden_field(:soft_delete) + link_to(name, "javascript:void(0);", :class => "delete_#{association.to_s} delete_link icon_link")
        end

        def nested_record_id(builder, assocation)
          builder.object.id.nil? ? "new_nested_record" : "#{assocation.to_s.singularize}_#{builder.object.id}"
        end

        def operator_options(type=nil)
          return Discerner::Operator.not_deleted.map{|o| [o.text, o.id, {:class => o.css_class_name}]} if type.blank?
          Discerner::Operator.joins(:parameter_types).where("discerner_parameter_types.name in (?)", type).
            select('DISTINCT text, discerner_operators.id, discerner_operators.binary').
            map {|o| [o.text, o.id, {:class => o.css_class_name}]}
        end

        def dictionary_options
          Discerner::Dictionary.not_deleted.map{|d| [d.name, d.id, {:class => d.css_class_name}]}
        end
        
        def combined_searches_options
          @discerner_searches.map {|s| [s.display_name, s.id, {:class => s.dictionary.css_class_name}]}
        end

        def searchable_parameter_categories(search=nil)
          if search.blank? || !search.persisted?
            parameter_categories = Discerner::ParameterCategory.not_deleted.searchable 
          else
            parameter_categories = search.dictionary.searchable_categories
          end
          parameter_categories.all.sort{|a,b| a.parameters.searchable.length <=> b.parameters.searchable.length}
        end

        def searchable_parameters(search=nil)
          if search.blank? || !search.persisted?
            parameters = Discerner::Parameter.not_deleted.searchable
          else
            parameters = search.dictionary.searchable_categories.map{ |c| c.searchable_parameters }
          end
          parameters.all
        end

        def searchable_parameters_options
          searchable_parameters.map {|p| [p.name, p.id, {:class => "#{p.parameter_type.name} #{'exclusive' if p.exclusive}"}]}
        end

        def exportable_parameter_categories(search=nil)
          if search.blank? || !search.persisted?
            parameter_categories = Discerner::ParameterCategory.not_deleted 
          else
            parameter_categories = search.dictionary.parameter_categories
          end
          parameter_categories.all.sort{|a,b| a.parameters.length <=> b.parameters.length}
        end

        def search_parameter_values(search_parameter)
          search_parameter_values = search_parameter.parameter.parameter_type.name == 'list' ? search_parameter.search_parameter_values.chosen : search_parameter.search_parameter_values
          display_values = []
          search_parameter_values.each do |spv|
            value = spv.parameter_value.blank? ? spv.value : spv.parameter_value.name 
            operator = spv.operator.text unless spv.operator.blank?
            display_values << "#{operator} \"#{value}\" #{spv.additional_value}"
          end
          display_values.join(' or ')
        end
        
        def discerner_export_link
          link_to "Export", export_parameters_path(@discerner_search), :class => "icon_link export_link"
        end
      end
    end
  end
end