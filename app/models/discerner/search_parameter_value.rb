module Discerner
  class SearchParameterValue < ActiveRecord::Base
    unloadable
    include Discerner::Methods::Models::SearchParameterValue
  end
end
