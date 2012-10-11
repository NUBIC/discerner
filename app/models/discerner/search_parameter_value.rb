module Discerner
  class SearchParameterValue < ActiveRecord::Base
    belongs_to :search_parameter
    belongs_to :parameter_value
    belongs_to :operator
    
    attr_accessible :additional_value, :chosen, :display_order, :operator_id, 
    :parameter_value_id, :search_parameter_id, :value, :parameter_value, :operator
    
    scope :chosen, where(:chosen => true)
  end
end
