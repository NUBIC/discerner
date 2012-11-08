module Discerner
  class Search < ActiveRecord::Base
    has_many  :search_parameters
    validate  :check_search_parameters

    accepts_nested_attributes_for :search_parameters, :allow_destroy => true,
      :reject_if => proc { |attributes| attributes['parameter_id'].blank? && attributes['parameter'].blank? }
      
    attr_accessible :deleted_at, :name, :username, :search_parameters, :search_parameters_attributes
    
    def check_search_parameters
      if self.search_parameters.size < 1 || self.search_parameters.all?{|search_parameter| search_parameter.marked_for_destruction? }
        errors.add(:base,"Search should have at least one search parameter.")
      end
    end
  end
end
