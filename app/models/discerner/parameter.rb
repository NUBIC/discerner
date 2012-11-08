module Discerner
  class Parameter < ActiveRecord::Base
    belongs_to      :parameter_category
    belongs_to      :parameter_type
    has_many        :parameter_values
    validates       :name, :database_name, :parameter_category, :parameter_type, :presence => true
    validates       :database_name, :uniqueness => true
    attr_accessible :database_name, :deleted_at, :name, :parameter_category, :parameter_category_id, :parameter_type, :parameter_type_id
    
    scope :not_deleted, where(:deleted_at => nil)
    
    def deleted?
      not deleted_at.blank?
    end
  end
end
