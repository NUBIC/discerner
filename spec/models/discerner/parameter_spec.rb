require 'spec_helper'

describe Discerner::Parameter do
  let!(:parameter) { Factory.create(:parameter) }

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
  
  it "validates that parameter has a parameter type" do
    p = Discerner::Parameter.new()
    p.should_not be_valid
    p.errors.full_messages.should include 'Parameter type can\'t be blank'
  end
   
  it "validates uniqueness of search_attribute for not-deleted records" do
    p = Discerner::Parameter.new(:name => 'new parameter',
      :search_attribute => parameter.search_attribute, 
      :search_model => parameter.search_model, 
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type)
      
    p.should_not be_valid
    p.errors.full_messages.should include 'Search attribute for parameter category and model has already been taken'
  end
  
  it "allows to re-use search_attribute for different search_model" do
    p = Discerner::Parameter.new(:name => 'new parameter',
      :search_attribute => parameter.search_attribute, 
      :search_model => 'other model', 
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type)
      
    p.should be_valid
  end
  
  it "allows to re-use search_model with different search_attribute" do
    p = Discerner::Parameter.new(:name => 'new parameter',
      :search_attribute => 'other_attribute', 
      :search_model => parameter.search_model, 
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type)
      
    p.should be_valid
  end
  
  it "allows to re-use search_model and search_attribute in different category" do
    p = Discerner::Parameter.new(:name => 'new parameter',
      :search_attribute => parameter.search_attribute,
      :search_model => parameter.search_model, 
      :parameter_category => Factory.create(:parameter_category, :name => 'other category'),
      :parameter_type => parameter.parameter_type)
      
    p.should be_valid
  end
  
  it "does not allow to reuse search_attribute if record has been deleted" do
    d = Discerner::Parameter.new(:name => 'new parameter', 
      :search_attribute => parameter.search_attribute, 
      :search_model => parameter.search_model,
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type,
      :deleted_at => Time.now)
    d.should_not be_valid
    
    Factory.create(:parameter, :name => 'deleted parameter', 
      :search_attribute => 'deleted_parameter',
      :search_model => 'deleted_parameter_model',
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type,
      :deleted_at => Time.now)
      
    d = Discerner::Parameter.new(:name => 'deleted parameter', 
    :search_attribute => 'deleted_parameter',
    :search_model => 'deleted_parameter_model',
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type)
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
