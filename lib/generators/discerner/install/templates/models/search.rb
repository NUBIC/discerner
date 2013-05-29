module Discerner
  module SearchCustomMethods
  end

  class Search < ActiveRecord::Base
    include Discerner::Methods::Models::Search
    include Discerner::SearchCustomMethods
  end
end