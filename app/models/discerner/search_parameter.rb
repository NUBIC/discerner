module Discerner
  class SearchParameter < ActiveRecord::Base
    belongs_to :search
    belongs_to :parameter
    has_many   :search_parameter_values, :dependent => :destroy
    
    accepts_nested_attributes_for :search_parameter_values, :allow_destroy => true
    attr_accessible :display_order, :parameter_id, :search_id, :parameter, :search, :search_parameter_values_attributes
  end
end
