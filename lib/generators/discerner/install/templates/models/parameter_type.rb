module Discerner
  module ParameterTypeCustomMethods
  end

  class ParameterType < ActiveRecord::Base
    include Discerner::Methods::Models::ParameterType
    include Discerner::ParameterTypeCustomMethods
  end
end
