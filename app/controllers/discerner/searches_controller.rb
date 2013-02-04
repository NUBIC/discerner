module Discerner
  class SearchesController < Discerner::ApplicationController
    unloadable
    include Discerner::Methods::Controllers::SearchesController
  end
end
