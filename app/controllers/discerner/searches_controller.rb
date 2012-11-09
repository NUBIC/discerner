require_dependency "discerner/application_controller"

module Discerner
  class SearchesController < ApplicationController
    include ApplicationHelper
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
  end
end
