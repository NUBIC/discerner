module Discerner
  module SearchesControllerCustomMethods
    def self.included(base)
      # base.send :before_filter, :load_search, :only => [:edit, :update, :rename, :destroy, :show]
    end

    def new
      super
    end

    def create
      super
    end

    def edit
      super
    end

    def update
      super
    end

    def index
      super
    end

    def destroy
      super
    end

    def show
      super
    end
  end

  class SearchesController < ApplicationController
    include Discerner::Methods::Controllers::SearchesController
    include Discerner::SearchesControllerCustomMethods
  end
end