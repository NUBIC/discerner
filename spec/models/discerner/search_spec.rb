require 'spec_helper'

describe Discerner::Search do
  let!(:search) { 
    s = Factory.build(:search)
    s.search_parameters << Factory.build(:search_parameter, :search => s)
    s.save!
    s
  }
  
  it "is valid with valid attributes" do
    search.should be_valid
  end
  
  it "validates that search has at least one search criteria" do
    s = Discerner::Search.new()
    s.should_not be_valid
    s.errors.full_messages.should include 'Search should have at least one search criteria.'
  end
  
  it "should accept attributes for search criterias" do
    s = Discerner::Search.new( :username => 'me', :search_parameters_attributes => { "0" => { :parameter => Discerner::Parameter.last}})
    s.should be_valid
    s.save
    s.should have(1).search_parameters
  end
  
  it "does not force that search has a username" do
    c = Discerner::Search.new(:search_parameters_attributes => { "0" => { :parameter => Discerner::Parameter.last}})
    c.should be_valid
    c.errors.full_messages.should_not include 'Username can\'t be blank'
  end
end
