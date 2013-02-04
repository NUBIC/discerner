module Discerner
  class ParameterValue < ActiveRecord::Base
    unloadable
    include Discerner::Methods::Models::ParameterValue
  end
end
