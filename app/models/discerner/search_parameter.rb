module Discerner
  class SearchParameter < ActiveRecord::Base
    unloadable
    include Discerner::Methods::Models::SearchParameter
  end
end
