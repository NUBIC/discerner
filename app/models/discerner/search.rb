module Discerner
  class Search < ActiveRecord::Base
    validates :username, :presence => true
    attr_accessible :deleted_at, :name, :username
  end
end
