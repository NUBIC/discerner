module Discerner
  class ParameterType < ActiveRecord::Base
    unloadable
    include Discerner::Methods::Models::ParameterType
  end
end