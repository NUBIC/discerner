module Discerner
  class ParameterCategory < ActiveRecord::Base
    unloadable
    include Discerner::Methods::Models::ParameterCategory
  end
end
