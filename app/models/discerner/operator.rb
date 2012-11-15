module Discerner
  class Operator < ActiveRecord::Base
    has_and_belongs_to_many :parameter_types, :join_table => :discerner_operators_parameter_types
    has_many        :search_parameter_values
    validates       :symbol, :presence => true, :uniqueness => {:message => "for operator has already been taken"}
    attr_accessible :binary, :deleted_at, :symbol, :text
    
    scope :not_deleted, where(:deleted_at => nil)
    
    def deleted?
      not deleted_at.blank?
    end
    
    def css_class_name
      css_class = parameter_types.map{ |t| t.name }.join(' ')
      css_class += ' binary' unless binary.blank?
      css_class
    end
  end
end
