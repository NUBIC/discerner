module Discerner
  class SearchCombination < ActiveRecord::Base
    unloadable
    include Discerner::Methods::Models::SearchCombination
  end
end
