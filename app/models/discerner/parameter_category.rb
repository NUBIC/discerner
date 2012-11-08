module Discerner
  class ParameterCategory < ActiveRecord::Base
    belongs_to      :dictionary
    has_many        :parameters
    validates       :name, :presence => true, :uniqueness => { :scope => :dictionary_id, :message => "for parameter category has already been taken"}
    validates       :dictionary, :presence => true
    attr_accessible :deleted_at, :dictionary, :dictionary_id, :name
    
    scope :not_deleted, where(:deleted_at => nil)
    
    def deleted?
      not deleted_at.blank?
    end
  end
end
