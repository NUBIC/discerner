module Discerner
  module Methods
    module Controllers
      module SearchesController
        def self.included(base)
          base.send :before_filter, :load_search, :only => [:edit, :update, :rename, :destroy, :show]
          base.send :before_filter, :load_combined_searches, :except => :index
        end
        
        def new
          @discerner_search = Discerner::Search.new
          @discerner_search.search_parameters.build()
          @discerner_search.search_combinations.build()
        end

        def create
          @discerner_search = Discerner::Search.new(params[:search])
          respond_to do |format|
            if @discerner_search.save
              format.html { redirect_to(edit_search_path(@discerner_search)) }
            else
              format.html { render :action => "new" }
            end
          end
        end

        def edit
          if dictionary_model
            if not dictionary_model.respond_to?('search')
              error_message = "Model '#{dictionary_model_name}' does not have 'search' method. You need to implement it to be able to run search on this dictionary"
            else
             dictionary_model.search(@discerner_search)
            end
          else
            error_message = "Model '#{dictionary_model_name}' could not be found. You need to create it to be able to run search on this dictionary"
          end
          flash[:error] = error_message unless error_message.blank?
        end

        def update
          respond_to do |format|
            if @discerner_search.update_attributes(params[:search])
              format.html { redirect_to(edit_search_path(@discerner_search), :notice => 'Search was successfully updated.') }
              format.js
            else
              format.html { render :action => "edit" }
              format.js
            end
          end
        end

        def index
          if discerner_user.blank?
            searches = Discerner::Search.not_deleted.where(:username => nil)
          else
            searches = Discerner::Search.not_deleted.where(:username => discerner_user.username)
          end

          if params[:query].blank?
            @discerner_searches = searches.all
          else
            @discerner_searches = searches.where('name like ?', '%' + params[:query] + '%')
          end
        end

        def destroy
          @discerner_search.deleted_at = Time.now
          @discerner_search.save
          respond_to do |format|
            format.html { redirect_to searches_path }
          end
        end
        
        def show
          if dictionary_model
            if not dictionary_model.respond_to?('to_csv')
              error_message = "Model '#{dictionary_model_name}' does not have 'to_csv' method. You need to implement it to be able to run export on this dictionary"
            end
          else
            error_message = "Model '#{dictionary_model_name}' could not be found. You need to create it to be able to run export on this dictionary"
          end
          flash[:error] = error_message unless error_message.blank?

          respond_to do |format|
            if error_message
              format.html
              format.csv { redirect_to :action => :export }
            else
              format.html
              format.csv do
                filename ="#{@discerner_search.parameterized_name}_#{Date.today.strftime('%m_%d_%Y')}"
                csv_data = dictionary_model.to_csv(@discerner_search, params)
                send_data csv_data,
                  :type => 'text/csv; charset=iso-8859-1; header=present',
                  :disposition => "attachment; filename=#{filename}.csv"
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
          
          def load_combined_searches
            if @discerner_search && @discerner_search.persisted?
              @discerner_searches = Discerner::Search.not_deleted.where('id != ? and dictionary_id = ?', @discerner_search.id, @discerner_search.dictionary_id).all
            else
              @discerner_searches = Discerner::Search.not_deleted.all
            end
          end
     end
    end
  end
end
