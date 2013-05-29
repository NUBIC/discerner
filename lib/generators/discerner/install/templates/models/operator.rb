module Discerner
  module OperatorCustomMethods
  end

  class Operator < ActiveRecord::Base
    include Discerner::Methods::Models::Operator
    include Discerner::OperatorCustomMethods
  end
end
