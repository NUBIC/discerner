module Discerner
  class ParametersController < Discerner::ApplicationController
    unloadable
    include Discerner::Methods::Controllers::ParametersController
  end
end
