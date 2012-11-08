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
   
  it "validates uniqueness of database_name for not-deleted records" do
    p = Discerner::Parameter.new(:name => 'new parameter',
      :database_name => parameter.database_name, 
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type)
      
    p.should_not be_valid
    p.errors.full_messages.should include 'Database name has already been taken'
  end
  
  it "does not allow to reuse database_name if record has been deleted" do
    d = Discerner::Parameter.new(:name => 'new parameter', 
      :database_name => parameter.database_name, 
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type,
      :deleted_at => Time.now)
    d.should_not be_valid
    
    Factory.create(:parameter, :name => 'deleted parameter', 
      :database_name => 'deleted_parameter',
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type,
      :deleted_at => Time.now)
    d = Discerner::Parameter.new(:name => 'deleted parameter', 
      :database_name => 'deleted_parameter',
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
