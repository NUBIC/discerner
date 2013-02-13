require 'spec_helper'

describe Discerner::Search do
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
    search.should be_valid
  end
  
  it "validates that search belongs to a dictionary" do
    s = Discerner::Search.new()
    s.should_not be_valid
    s.errors.full_messages.should include 'Dictionary for search can\'t be blank'
  end
  
  it "validates that search has at least one search criteria" do
    s = Discerner::Search.new()
    s.should_not be_valid
    s.errors.full_messages.should include 'Search should have at least one search criteria.'
  end
  
  it "should accept attributes for search criterias" do
    s = Discerner::Search.new( :username => 'me', :search_parameters_attributes => { "0" => { :parameter => Discerner::Parameter.last}}, :dictionary => Discerner::Dictionary.last)
    s.should be_valid
    s.save
    s.should have(1).search_parameters
  end
  
  it "does not force that search has a username" do
    s = Discerner::Search.new(:search_parameters_attributes => { "0" => { :parameter => Discerner::Parameter.last}})
    s.dictionary = Discerner::Dictionary.last
    s.should be_valid
    s.errors.full_messages.should_not include 'Username can\'t be blank'
  end
  
  it "allows to access combined searches" do
    c = search_combination
    c.save!
    search.reload.combined_searches.length.should == 1
  end
  
end
