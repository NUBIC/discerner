module Discerner
  module SearchCombinationCustomMethods
  end

  class SearchCombination < ActiveRecord::Base
    include Discerner::Methods::Models::SearchCombination
    include Discerner::SearchCombinationCustomMethods
  end
end