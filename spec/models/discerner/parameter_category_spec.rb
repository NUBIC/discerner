require 'spec_helper'

describe Discerner::ParameterCategory do
  let!(:parameter_category) { Factory.create(:parameter_category) }
  
  it "is valid with valid attributes" do
    parameter_category.should be_valid
  end
  
  it "validates that category belongs to a dictionary" do
    c = Discerner::ParameterCategory.new(:name => parameter_category.name)
    c.should_not be_valid
    c.errors.full_messages.should include 'Dictionary can\'t be blank'
  end
  
  it "validates that category has a name" do
    c = Discerner::ParameterCategory.new(:dictionary => parameter_category.dictionary)
    c.should_not be_valid
    c.errors.full_messages.should include 'Name can\'t be blank'
  end
  
  it "validates uniqueness of name for not-deleted records in the same dictionary" do
    c = Discerner::ParameterCategory.new(:name => parameter_category.name, :dictionary => parameter_category.dictionary)
    c.should_not be_valid
    c.errors.full_messages.should include 'Name for parameter category has already been taken'
  end
  
  it "does not allow to reuse name if record has been deleted" do
    c = Discerner::ParameterCategory.new(:name => parameter_category.name, :dictionary => parameter_category.dictionary, :deleted_at => Time.now)
    c.should_not be_valid
    
    Factory.create(:parameter_category, :name => 'deleted parameter_category', :dictionary => parameter_category.dictionary, :deleted_at => Time.now)
    d = Discerner::ParameterCategory.new(:name => 'deleted parameter_category', :dictionary => parameter_category.dictionary)
    d.should_not be_valid
    
    d.deleted_at = Time.now
    d.should_not be_valid
  end
  
  it "allows to reuse name from different dictionary" do
    c = Discerner::ParameterCategory.new(:name => parameter_category.name, :dictionary => Factory.create(:dictionary, :name => "even better dictionary"))
    c.should be_valid
  end

  it "allows to access dictionary from parameter_category" do
    parameter_category.should respond_to :dictionary
  end
end
