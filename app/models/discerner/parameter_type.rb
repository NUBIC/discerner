module Discerner
  class ParameterType < ActiveRecord::Base
    has_many        :parameters
    validates       :name, :presence => true, :uniqueness => {:scope => :deleted_at, :message => "for parameter type has already been taken"}
    attr_accessible :deleted_at, :name
  end
end