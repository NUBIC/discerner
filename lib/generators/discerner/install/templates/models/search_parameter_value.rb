module Discerner
  module SearchParameterValueCustomMethods
  end

  class SearchParameterValue < ActiveRecord::Base
    include Discerner::Methods::Models::SearchParameterValue
    include Discerner::SearchParameterValueCustomMethods
  end
end