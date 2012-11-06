module Discerner
  class ParameterCategory < ActiveRecord::Base
    belongs_to      :dictionary
    has_many        :parameters
    validates       :name, :presence => true, :uniqueness => { :scope => :dictionary_id, :message => "for parameter category has already been taken"}
    validates       :dictionary, :presence => true
    attr_accessible :deleted_at, :dictionary, :dictionary_id, :name
  end
end
