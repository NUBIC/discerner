module Discerner
  class ParameterType < ActiveRecord::Base
    has_many        :parameters
    has_and_belongs_to_many :operators, :join_table => :discerner_operators_parameter_types
    
    validates       :name, :presence => true, :uniqueness => {:message => "for parameter type has already been taken"}
    attr_accessible :deleted_at, :name
    
    def deleted?
      not deleted_at.blank?
    end
  end
end