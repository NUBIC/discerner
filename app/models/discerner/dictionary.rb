module Discerner
  class Dictionary < ActiveRecord::Base
    has_many        :parameter_categories
    validates       :name, :presence => true, :uniqueness => {:scope => :deleted_at, :message => "for dictionary has already been taken"}
    attr_accessible :name, :deleted_at
  end
end
