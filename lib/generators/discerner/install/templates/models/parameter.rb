module Discerner
  module ParameterCustomMethods
  end

  class Parameter < ActiveRecord::Base
    include Discerner::Methods::Models::Parameter
    include Discerner::ParameterCustomMethods
  end
end

