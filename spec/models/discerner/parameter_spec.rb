require 'spec_helper'

describe Discerner::Parameter do
  let(:parameter) { Factory.create(:parameter) }

  it "is valid with valid attributes" do
    parameter.should be_valid
  end
  
  it "validates that parameter has a name" do
    p = Discerner::Parameter.new()
    p.should_not be_valid
    p.errors.full_messages.should include 'Name can\'t be blank'
  end
  
  it "validates that parameter belongs to a parameter category" do
    p = Discerner::Parameter.new()
    p.should_not be_valid
    p.errors.full_messages.should include 'Parameter category can\'t be blank'
  end
  
  it "validates that searchable parameter has parameter type, model and attribute" do
    p = Factory.build(:parameter, :search_model => 'A')
    p.should_not be_valid
    p.errors.full_messages.should include 'Searchable parameter should search model, search method and parameter_type defined.'
    
    p = Factory.build(:parameter, :search_method => 'A')
    p.should_not be_valid
    p.errors.full_messages.should include 'Searchable parameter should search model, search method and parameter_type defined.'
    
    p = Factory.build(:parameter, :search_model => 'A', :search_method => 'A')
    p.parameter_type = nil
    p.should_not be_valid
    p.errors.full_messages.should include 'Searchable parameter should search model, search method and parameter_type defined.'
    
    p = Factory.build(:parameter, :search_model => 'A', :search_method => 'A', :parameter_type => Discerner::ParameterType.last || Factory(:parameter_type) )
    p.should be_valid
  end
   
  it "validates uniqueness of unique_identifier" do
    p1 = parameter
    p = Discerner::Parameter.new(:name => 'new parameter',
      :unique_identifier => p1.unique_identifier, 
      :parameter_category => p1.parameter_category)
      
    p.should_not be_valid
    p.errors.full_messages.should include 'Unique identifier has to be unique within dictionary.'
  end
  
  it "allows to re-use unique_identifier in different dictionary" do
    p = Discerner::Parameter.new(:name => 'new parameter',
      :unique_identifier => parameter.unique_identifier, 
      :parameter_category => Factory.create(:parameter_category, :name => 'other category', :dictionary => Factory.create(:dictionary, :name => "other dictionary")))  
    p.should be_valid
  end
  
  it "does not allow to reuse unique_identifier if record has been deleted" do
    d = Discerner::Parameter.new(:name => 'new parameter', 
      :unique_identifier => parameter.unique_identifier, 
      :parameter_category => parameter.parameter_category,
      :deleted_at => Time.now)
    d.should_not be_valid
    
    Factory.create(:parameter, :name => 'deleted parameter', 
      :unique_identifier => 'deleted_unique_identifier',
      :parameter_category => parameter.parameter_category,
      :deleted_at => Time.now)
      
    d = Discerner::Parameter.new(:name => 'deleted parameter', 
      :unique_identifier => 'deleted_unique_identifier',
      :parameter_category => parameter.parameter_category)
    d.should_not be_valid
    
    d.deleted_at = Time.now
    d.should_not be_valid
  end

  it "allows to access parameter values if exist" do
    parameter_value = Factory.create(:parameter_value, :parameter => parameter)
    
    parameter = Discerner::Parameter.last
    parameter.parameter_values.length.should == 1
    parameter.parameter_values.first.id.should == parameter_value.id
  end
  
  it "detects if record has been marked as deleted" do
    parameter.deleted_at = Time.now
    parameter.should be_deleted
  end
end
