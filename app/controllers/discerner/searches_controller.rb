module Discerner
  class SearchesController < Discerner::ApplicationController
    include ApplicationHelper
    
    before_filter :load_search,     :only => [:edit, :update, :rename]
    before_filter :load_parameters, :except => :index
    
    def new
      @search = Discerner::Search.new
      @search.search_parameters.build()
    end
    
    def create
      @search = Discerner::Search.new(params[:search])
      respond_to do |format|
        if @search.save
          format.html { redirect_to(edit_search_path(@search)) }
        else
          format.html { render :action => "new" }
        end
      end
    end
    
    def edit
      dictionary_model_name = @search.dictionary.parameterized_name.camelize
      dictionary_model = dictionary_model_name.safe_constantize
      if dictionary_model
        if not dictionary_model.respond_to?('search')
          flash[:error] = "Model '#{dictionary_model_name}' does not have 'search' method. You need to implement it to be able to run search on this dictionary"
        else
         dictionary_model.search(@search)
        end
      else
        flash[:error] = "Model '#{dictionary_model_name}' could not be found. You need to create it to be able to run search on this dictionary"
      end
    end
    
    def update
      respond_to do |format|
        if @search.update_attributes(params[:search])
          format.html { redirect_to(edit_search_path(@search), :notice => 'Search was successfully updated.') }
          format.js
        else
          format.html { render :action => "edit" }
          format.js
        end
      end
    end
    
    def index
      if discerner_user.blank?
        searches = Discerner::Search.where(:username => nil)
      else
        searches = Discerner::Search.where(:username => discerner_user.username)
      end
      
      if params[:query].blank?
        @searches = searches.all
      else
        @searches = searches.where('name like ?', '%' + params[:query] + '%')
      end
    end

    private
      def load_parameters
        @dictionaries = Discerner::Dictionary.not_deleted.all
        if @search && @search.persisted?
          @parameter_categories = Discerner::ParameterCategory.not_deleted.where(:dictionary_id => @search.dictionary_id).all
          @parameters = Discerner::Parameter.not_deleted.where(:parameter_category_id => @parameter_categories.map{ |c| c.id})
        else
          @parameter_categories = Discerner::ParameterCategory.not_deleted.all
          @parameters = Discerner::Parameter.not_deleted.all
        end
      end
      
      def load_search
        @search = Discerner::Search.find(params[:id])
      end
  end
end
