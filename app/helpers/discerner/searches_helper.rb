module Discerner
  module SearchesHelper
    def discerner_results_partial
      "dictionaries/#{@search.dictionary.parameterized_name}/results"
    end
  end
end
