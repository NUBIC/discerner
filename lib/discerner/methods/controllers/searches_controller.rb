module Discerner
  module Methods
    module Controllers
      module SearchesController
        def self.included(base)
          base.send :before_filter, :load_search, only: [:edit, :update, :rename, :destroy, :show]
        end

        def new
          set_searchable_dictionaries
          if @searchable_dictionaries.any?
            set_searchables
            @discerner_search = Discerner::Search.new
          else
            flash[:error] = 'No searchable dictionaries found. Make sure that dictionaries are loaded.'
          end
        end

        def create
          @discerner_search           = Discerner::Search.new(search_params)
          @discerner_search.username  = discerner_user.username unless discerner_user.blank?

          set_searchable_dictionaries
          set_searchables
          respond_to do |format|
            if @discerner_search.save
              format.html { redirect_to(edit_search_path(@discerner_search)) }
            else
              format.html { render action: "new" }
            end
          end
        end

        def edit
          set_searchable_dictionaries
          set_searchables

          if @discerner_search.disabled?
            error_message = "There is an issue with the this search that has to be corrected before it can be executed"
            if @discerner_search.warnings.any?
              error_message << ': '
              error_message << @discerner_search.warnings.full_messages.join(',')
            end
          else
            if dictionary_model
              dictionary =  dictionary_model.new(@discerner_search)
              if dictionary.respond_to?('search')
                @results = dictionary.search(params, dictionary_search_options)
                @discerner_search.last_executed = Time.now
                @discerner_search.save!
              else
                error_message = "Model '#{dictionary_model_name}' instance does not respond to 'search' method. You need to implement it to be able to run search on this dictionary"
              end
            else
              error_message = "Model '#{dictionary_model_name}' could not be found. You need to create it to be able to run search on this dictionary"
            end
          end
          flash[:error] = error_message unless error_message.blank?
        end

        def update
          set_searchable_dictionaries
          set_searchables
          respond_to do |format|
            if @discerner_search.update_attributes(search_params)
              format.html { redirect_to(edit_search_path(@discerner_search), notice: 'Search was successfully updated.') }
              format.js
            else
              format.html { render action: "edit" }
              format.js
            end
          end
        end

        def index
          searches = Discerner::Search.not_deleted.includes(
            :dictionary,
            :export_parameters   => [parameter: [:parameter_type]],
            search_combinations: [combined_search: [search_parameters: [parameter: [:parameter_type], search_parameter_values: [:parameter_value]]]],
            :search_parameters   => [parameter: [:parameter_type], search_parameter_values: [:parameter_value]])

          username = discerner_user.username unless discerner_user.blank?
          searches = searches.by_user(username) unless username.blank?

          searches = searches.where('discerner_searches.name like ?', '%' + params[:query] + '%') unless params[:query].blank?
          @discerner_searches = searches.order("discerner_searches.last_executed DESC")
        end

        def destroy
          @discerner_search.deleted_at = Time.now
          @discerner_search.save
          respond_to do |format|
            format.html { redirect_to searches_path }
          end
        end

        def show
          if @discerner_search.disabled?
            error_message = "There is an issue with the this search that has to be corrected before it can be exported"
            if @discerner_search.warnings.any?
              error_message << ': '
              error_message << @discerner_search.warnings.full_messages.join(',')
            end
          else
            if dictionary_model
              dictionary =  dictionary_model.new(@discerner_search)
              if not dictionary.respond_to?('export')
                error_message = "Model '#{dictionary_model_name}' instance does not respond to 'export' method. You need to implement it to be able to run export on this dictionary"
              end
            else
              error_message = "Model '#{dictionary_model_name}' could not be found. You need to create it to be able to run export on this dictionary"
            end
          end
          flash[:error] = error_message unless error_message.blank?

          respond_to do |format|
            if error_message
              format.html
              format.csv { redirect_to export_parameters_path(@discerner_search)  }
              format.xls { redirect_to export_parameters_path(@discerner_search)  }
            else
              @export_data = dictionary.export(params, dictionary_search_options)
              filename ="#{@discerner_search.parameterized_name}_#{Date.today.strftime('%m_%d_%Y')}"
              format.html
              format.csv do

                send_data @export_data,
                  type: 'text/csv; charset=iso-8859-1; header=present',
                  disposition: "attachment; filename=#{filename}.csv"
              end
              format.xls do
                headers["Content-type"] = "application/vnd.ms-excel"
                headers['Content-Transfer-Encoding'] = 'binary'
                headers['Expires'] = '0'
                headers['Pragma'] = 'public'
                headers["Cache-Control"] = "must-revalidate, post-check=0, pre-check=0"
                headers["Content-Disposition"] = "attachment; filename=\"#{filename}.xls\""
                headers['Content-Description'] = 'File Transfer'
                render "discerner/dictionaries/#{@discerner_search.dictionary.parameterized_name}/show"
              end
            end
          end
        end

        private
          def load_search
            @discerner_search = Discerner::Search.find(params[:id])
          end

          def dictionary_model_name
            @discerner_search.dictionary.parameterized_name.camelize
          end

          def dictionary_model
            dictionary_model_name.safe_constantize
          end

          def dictionary_search_options
            options = { username: nil }
            options[:username] = discerner_user.username unless discerner_user.blank?
            options
          end

          def set_searchable_dictionaries
            if @discenrer_search && @discerner_search.persisted?
              @searchable_dictionaries = [@discerner_search.dictionary]
            else
              @searchable_dictionaries = Discerner::Dictionary.not_deleted
            end
          end

          def set_searchables
            if @discerner_search
              dictionary_ids = []
              dictionary_ids << @discerner_search.dictionary_id
            else
              dictionary_ids = @searchable_dictionaries.map(&:id)
            end

            @searchable_parameter_categories  = Discerner::ParameterCategory.includes(:dictionary).where(dictionary_id: dictionary_ids).not_deleted.searchable.ordered_by_name.to_a
            parameters_available              = Discerner::Parameter.includes(:parameter_type, parameter_category: [:dictionary]).where(parameter_category_id: @searchable_parameter_categories.map(&:id)).not_deleted.searchable.to_a
            parameters_used                   = @discerner_search && @discerner_search.persisted? ? @discerner_search.search_parameters.map{ |sp| sp.parameter } : []
            @searchable_parameters            = parameters_available.flatten | parameters_used.flatten
            @searchable_parameter_values      = map_searchable_values
          end

          def map_searchable_values
            searchable_values = {}

            # getting all values at once to save database calls
            values_available = Discerner::ParameterValue.joins('LEFT JOIN discerner_parameter_value_categorizations ON discerner_parameter_values.id = discerner_parameter_value_categorizations.parameter_value_id LEFT JOIN discerner_parameter_value_categories ON discerner_parameter_value_categorizations.parameter_value_category_id = discerner_parameter_value_categories.id ').not_deleted.where(:parameter_id => @searchable_parameters.map(&:id)).ordered_by_parameter_and_name.select('discerner_parameter_values.*, discerner_parameter_value_categories.name AS category_name').to_a
            values_used = []
            if @discerner_search && @discerner_search.persisted?
              values_used = Discerner::ParameterValue.joins('LEFT JOIN discerner_parameter_value_categorizations ON discerner_parameter_values.id = discerner_parameter_value_categorizations.parameter_value_id LEFT JOIN discerner_parameter_value_categories ON discerner_parameter_value_categorizations.parameter_value_category_id = discerner_parameter_value_categories.id ').joins(:search_parameter_values => :search_parameter).where(:discerner_search_parameters => {:search_id => @discerner_search.id}).ordered_by_parameter_and_name.select('discerner_parameter_values.*, discerner_parameter_value_categories.name AS category_name').to_a
            end

            @searchable_parameters.each do |sp|
              values  = values_available.select{|pv| pv.parameter_id == sp.id} | values_used.select{|pv| pv.parameter_id == sp.id}
              searchable_values[sp.id] = values.uniq.reject{|v| v.blank?}
            end
            searchable_values
          end

          def search_params
            params.require(:search).permit(:id, :dictionary_id, :deleted_at, :name, :username, :_destroy,
              search_combinations_attributes: [:display_order, :operator_id, :combined_search_id, :_destroy],
              search_parameters_attributes: [:display_order, :parameter_id, :_destroy, :id,
                search_parameter_values_attributes: [:id, :display_order, :operator_id, :chosen, :parameter_value_id, :value, :additional_value, :_destroy]])
          end
     end
    end
  end
end
