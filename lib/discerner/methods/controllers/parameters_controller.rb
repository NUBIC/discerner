module Discerner
  module Methods
    module Controllers
      module ParametersController
        def self.included(base)
          base.send :before_filter, :load_parameter
        end

        def values
          @parameter_values = @parameter.parameter_values.not_deleted.order('name')
          @search_parameter_value_id = params[:search_parameter_value_id]
          respond_to do |format|
            format.html { render :layout => false }
            format.json { render :text => { :type => @parameter.parameter_type.name,
              :parameter_values => @parameter_values.map { |v| { :parameter_value_id => v.id, :name => v.name } }}.to_json }
          end
        end

        private
          def load_parameter
            id = params[:id]
            id ||= params[:parameter_id]
            @parameter = Parameter.find(id)
          end
      end
    end
  end
end
