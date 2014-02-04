module Discerner
  module Methods
    module Controllers
      module ExportParametersController
        def self.included(base)
          base.send :helper, :all
          base.send :before_filter, :load_search
          base.send :layout, 'layouts/discerner/searches'
        end

        def index
          if @discerner_search.disabled?
            error_message = "There is an issue with the this export that has to be corrected before it can be executed"
            if @discerner_search.warnings.any?
              error_message << ': '
              error_message << @discerner_search.warnings.full_messages.join(',')
            end
          end
          flash[:error] = error_message unless error_message.blank?
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
