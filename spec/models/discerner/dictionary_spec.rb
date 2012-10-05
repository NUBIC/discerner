require 'spec_helper'

describe Discerner::Dictionary do
  let!(:dictionary) { Factory.create(:dictionary) }

  it "is valid with valid attributes" do
    dictionary.should be_valid
  end
  
  it "validates uniqueness of name for not-deleted records" do
    d = Discerner::Dictionary.new(:name => dictionary.name)
    d.should_not be_valid
  end
  
  it "allows to reuse name if record has been deleted" do
    d = Discerner::Dictionary.new(:name => dictionary.name, :deleted_at => Time.now)
    d.should be_valid
    
    Factory.create(:dictionary, :name => 'deleted dictionary', :deleted_at => Time.now)
    d = Discerner::Dictionary.new(:name => 'deleted dictionary')
    d.should be_valid
    
    d.deleted_at = Time.now
    d.should be_valid
  end

  it "allows to access parameter_categories for dictionary" do
    dictionary.should respond_to :parameter_categories
  end
end