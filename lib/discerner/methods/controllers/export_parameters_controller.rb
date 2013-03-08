module Discerner
  module Methods
    module Controllers
      module ExportParametersController
        def self.included(base)
          base.send :helper, :all
          base.send :before_filter, :load_search
        end

        def index
          flash[:error] = "There is an issue with the this export that has to be corrected before it can be executed" if @discerner_search.disabled?
        end

        def assign
          existing_export_parameters = @discerner_search.export_parameters || []
          export_parameter_ids = params[:parameter_ids] || []

          existing_export_parameters.map{ |export_parameter| export_parameter.delete unless export_parameter_ids.include?(export_parameter.parameter_id) }
          export_parameter_ids.map{ |parameter_id| @discerner_search.export_parameters.create(:parameter_id => parameter_id) unless existing_export_parameters.where(:parameter_id => parameter_id).any?}
          redirect_to search_path(@discerner_search, :format => 'xls')
        end

        private
          def load_search
            @discerner_search = Discerner::Search.find(params[:id])
          end
      end
    end
  end
end
