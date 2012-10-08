module Discerner
  class Operator < ActiveRecord::Base
    has_and_belongs_to_many :parameter_types
    validates       :symbol, :presence => true, :uniqueness => {:scope => :deleted_at, :message => "for operator has already been taken"}
    attr_accessible :binary, :deleted_at, :symbol, :text
  end
end
