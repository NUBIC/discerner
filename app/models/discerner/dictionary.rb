module Discerner
  class Dictionary < ActiveRecord::Base
    unloadable
    include Discerner::Methods::Models::Dictionary
  end
end
