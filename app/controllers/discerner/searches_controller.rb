require_dependency "discerner/application_controller"

module Discerner
  class SearchesController < ApplicationController
    include ApplicationHelper
    
    before_filter :load_parameters, :except => :index
    before_filter :load_search, :only => [:edit, :update, :rename]
    
    def new
      @search = Discerner::Search.new
      @search.search_parameters.build()
    end
    
    def create
      @search = Search.new(params[:search])
      respond_to do |format|
        if @search.save
          format.html { redirect_to(edit_search_path(@search)) }
        else
          format.html { render :action => "new" }
        end
      end
    end
    
    def edit
      render :new
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
      if user_for_discerner.blank?
        searches = Search.where(:username => nil)
      else
        searches = Search.where(:username => user_for_discerner.username)
      end
      
      if params[:query].blank?
        @searches = searches.all
      else
        @searches = searches.where('name like ?', '%' + params[:query] + '%')
      end
    end

    private
      def load_parameters
        @parameters = Discerner::Parameter.not_deleted.all
        @parameter_categories = Discerner::ParameterCategory.not_deleted.all
        @dictionaries = Discerner::Dictionary.not_deleted.all
      end
      
      def load_search
        @search = Search.find(params[:id])
      end
  end
end
