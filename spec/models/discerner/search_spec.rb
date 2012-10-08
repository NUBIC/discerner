require 'spec_helper'

describe Discerner::Search do
  let!(:search) { Factory.create(:search) }
  
  it "is valid with valid attributes" do
    search.should be_valid
  end
  
  it "validates that search has a username" do
    c = Discerner::Search.new()
    c.should_not be_valid
    c.errors.full_messages.should include 'Username can\'t be blank'
  end
end
