module Discerner
  class Operator < ActiveRecord::Base
    unloadable
    include Discerner::Methods::Models::Operator
  end
end
