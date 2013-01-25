module Discerner
  module SearchesHelper
    def discerner_results_partial
      "discerner/dictionaries/#{@discerner_search.dictionary.parameterized_name}/results"
    end
  end
end
