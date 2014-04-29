module Discerner
  module ParameterValueCategoryCustomMethods
  end

  class ParameterValueCategory < ActiveRecord::Base
    include Discerner::Methods::Models::ParameterValueCategory
    include Discerner::ParameterValueCategoryCustomMethods
  end
end