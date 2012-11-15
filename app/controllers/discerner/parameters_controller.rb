require_dependency "discerner/application_controller"

module Discerner
  class ParametersController < ApplicationController
    before_filter :load_parameter
    
    def show
      @parameter_values = @parameter.parameter_values.order('name')
      respond_to do |format|
        format.json { render :text => { :type => @parameter.parameter_type.name,
          :parameter_values => @parameter_values.map { |v| { :parameter_value_id => v.id, :name => v.name } }}.to_json }
      end
    end
    
    private
      def load_parameter
        @parameter = Parameter.find(params[:id])
      end
  end
end
