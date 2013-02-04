module Discerner
  class Search < ActiveRecord::Base
    unloadable
    include Discerner::Methods::Models::Search
  end
end
