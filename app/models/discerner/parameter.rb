module Discerner
  class Parameter < ActiveRecord::Base
    belongs_to      :parameter_category
    belongs_to      :parameter_type
    
    validates       :name, :database_name, :parameter_category, :parameter_type, :presence => true
    validates       :database_name, :uniqueness => {:scope => :deleted_at}
    attr_accessible :database_name, :deleted_at, :name, :parameter_category, :parameter_type
  end
end
