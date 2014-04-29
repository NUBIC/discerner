module Discerner
  module ParameterValueCategorizationCustomMethods
  end

  class ParameterValueCategorization < ActiveRecord::Base
    include Discerner::Methods::Models::ParameterValueCategorization
    include Discerner::ParameterValueCategorizationCustomMethods
  end
end