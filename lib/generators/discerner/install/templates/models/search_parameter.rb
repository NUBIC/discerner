module Discerner
  module SearchParameterCustomMethods
  end

  class SearchParameter < ActiveRecord::Base
    include Discerner::Methods::Models::SearchParameter
    include Discerner::SearchParameterCustomMethods
  end
end