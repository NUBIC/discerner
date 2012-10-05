module Discerner
  class Dictionary < ActiveRecord::Base
    validates       :name, :presence => true, :uniqueness => {:scope => :deleted_at}
    attr_accessible :name, :deleted_at
  end
end
