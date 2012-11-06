module Discerner
  class Operator < ActiveRecord::Base
    has_and_belongs_to_many :parameter_types, :join_table => :discerner_operators_parameter_types
    has_many        :search_parameter_values
    validates       :symbol, :presence => true, :uniqueness => {:scope => :deleted_at, :message => "for operator has already been taken"}
    attr_accessible :binary, :deleted_at, :symbol, :text
    
    def deleted?
      not deleted_at.blank?
    end
  end
end
