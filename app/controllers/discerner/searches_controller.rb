require_dependency "discerner/application_controller"

module Discerner
  class SearchesController < ApplicationController
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
        searches = Discerner::Search.where(:username => nil)
      else
        searches = Discerner::Search.where(:username => user_for_discerner.username)
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
