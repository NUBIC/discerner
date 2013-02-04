module Discerner
  class Parameter < ActiveRecord::Base
    unloadable
    include Discerner::Methods::Models::Parameter
  end
end
