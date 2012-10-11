module Discerner
  class SearchParameter < ActiveRecord::Base
    belongs_to :search
    belongs_to :parameter
    
    #validates :search, :presence => true
    attr_accessible :display_order, :parameter_id, :search_id, :parameter, :search
  end
end
