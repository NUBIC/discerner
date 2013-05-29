module Discerner
  module ParameterValueCustomMethods
  end

  class ParameterValue < ActiveRecord::Base
    include Discerner::Methods::Models::ParameterValue
    include Discerner::ParameterValueCustomMethods
  end
end