module Discerner
  class ParameterCategory < ActiveRecord::Base
    belongs_to      :dictionary
    validates       :name, :presence => true, :uniqueness => { :scope => [:dictionary_id, :deleted_at]}
    attr_accessible :deleted_at, :dictionary, :dictionary_id, :name
  end
end
