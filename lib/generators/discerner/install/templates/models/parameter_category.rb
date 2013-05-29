module Discerner
  module ParameterCategoryCustomMethods
  end

  class ParameterCategory < ActiveRecord::Base
    include Discerner::Methods::Models::ParameterCategory
    include Discerner::ParameterCategoryCustomMethods
  end
end
