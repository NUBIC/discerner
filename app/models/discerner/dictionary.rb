module Discerner
  class Dictionary < ActiveRecord::Base
    has_many        :parameter_categories
    validates       :name, :presence => true, :uniqueness => {:message => "for dictionary has already been taken"}
    attr_accessible :name, :deleted_at
  
    scope :not_deleted, where(:deleted_at => nil)
  
    def deleted?
      not deleted_at.blank?
    end
    
    def css_class_name
      "dictionary_#{parameterized_name}"
    end
    
    def parameterized_name
      name.parameterize.underscore
    end
  end
end
