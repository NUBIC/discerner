require 'spec_helper'

describe Discerner::SearchCombination do
  let!(:search) { 
    s = Factory.build(:search)
    s.search_parameters << Factory.build(:search_parameter, :search => s)
    s.dictionary = Discerner::Dictionary.last
    s.save!
    s
  }
  
  let!(:search_combination) { 
    s = Factory.build(:search, :name => 'other search')
    s.search_parameters << Factory.build(:search_parameter, :search => s, :parameter => Factory.build(:parameter, :search_attribute => 'other_parameter'))
    s.save!
    Discerner::SearchCombination.new(:search => search, :combined_search => s)
  }
  it "is valid with valid attributes" do
    search_combination.should be_valid
  end
  
  it "allows to access parent search" do
    search_combination.should respond_to :search
  end
  
  it "allows to access combined search" do
    search_combination.should respond_to :combined_search
  end
  
  it "should not allow to combine search with itself" do
    c = Discerner::SearchCombination.new(:search => search, :combined_search => search)
    c.should_not be_valid
  end
end
