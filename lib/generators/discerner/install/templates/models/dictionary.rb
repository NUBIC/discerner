module Discerner
  module DictionaryCustomMethods
  end

  class Dictionary < ActiveRecord::Base
    include Discerner::Methods::Models::Dictionary
    include Discerner::DictionaryCustomMethods
  end
end
