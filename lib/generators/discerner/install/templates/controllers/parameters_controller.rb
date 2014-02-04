module Discerner
  module ParametersControllerCustomMethods
    def self.included(base)
    end

    def show
      super
    end
  end

  class ParametersController < ApplicationController
    include Discerner::Methods::Controllers::ParametersController
    include Discerner::ParametersControllerCustomMethods
  end
end