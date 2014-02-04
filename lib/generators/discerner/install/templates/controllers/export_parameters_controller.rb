module Discerner
  module ExportParametersControllerCustomMethods
    def self.included(base)
      base.send :layout, "search"
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