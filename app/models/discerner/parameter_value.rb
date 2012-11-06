module Discerner
  class ParameterValue < ActiveRecord::Base
    belongs_to      :parameter
    has_many        :search_parameter_values
    validates       :name, :parameter, :presence => true
    validates       :database_name, :presence => true, :uniqueness => {:scope => :parameter_id, :message => "for parameter value has already been taken"}
    attr_accessible :database_name, :deleted_at, :name, :parameter, :parameter_id
  end
end
