module Discerner
  class ParameterType < ActiveRecord::Base
    validates       :name, :presence => true, :uniqueness => {:scope => :deleted_at}
    attr_accessible :deleted_at, :name
  end
end