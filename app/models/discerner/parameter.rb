module Discerner
  class Parameter < ActiveRecord::Base
    belongs_to      :parameter_category
    belongs_to      :parameter_type
    has_many        :parameter_values
    validates       :name, :database_name, :parameter_category, :parameter_type, :presence => true
    validates       :database_name, :uniqueness => {:scope => :deleted_at}
    attr_accessible :database_name, :deleted_at, :name, :parameter_category, :parameter_type
    
    def find_or_create_parameter_value(name)
      parameter_value = parameter_values.where(:name => name).first
      unless parameter_value
        parameter_value = parameter_values.build(:name => name)
        parameter_value.created_at = Time.now
      end
      parameter_value.save
      parameter_value
    end
  end
end
