module Discerner
  module ExportParametersControllerCustomMethods
    def self.included(base)
      # base.send :helper, :all
      # base.send :before_filter, :load_search
    end

    def index
      super
    end

    def assign
      super
    end
  end

  class ExportParametersController < ApplicationController
    include Discerner::Methods::Controllers::ExportParametersController
    include Discerner::ExportParametersControllerCustomMethods
  end
end