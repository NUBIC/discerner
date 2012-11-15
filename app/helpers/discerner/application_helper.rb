module Discerner
  module ApplicationHelper
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
    
    # Returns the user who is responsible for any changes that occur.
    # By default this calls `current_user` and returns the result.
    # 
    # Override this method in your controller to call a different
    # method, e.g. `current_person`, or anything you like.
    def user_for_discerner
      current_user rescue nil
    end
  end
end
