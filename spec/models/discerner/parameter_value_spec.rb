require 'spec_helper'

describe Discerner::ParameterValue do
  let!(:parameter_value) { Factory.create(:parameter_value) }

  it "is valid with valid attributes" do
    parameter_value.should be_valid
  end
  
  it "validates that parameter value has a name" do
    c = Discerner::ParameterValue.new()
    c.should_not be_valid
    c.errors.full_messages.should include 'Name can\'t be blank'
  end
  
  it "validates that parameter value belongs to a parameter" do
    p = Discerner::ParameterValue.new()
    p.should_not be_valid
    p.errors.full_messages.should include 'Parameter can\'t be blank'
  end

  it "validates uniqueness of database_name for not-deleted records" do
    p = Discerner::ParameterValue.new(:name => 'new parameter',
      :database_name => parameter_value.database_name, 
      :parameter => parameter_value.parameter)
      
    p.should_not be_valid
    p.errors.full_messages.should include 'Database name for parameter value has already been taken'
  end
  
  it "does not allow to reuse database_name if record has been deleted" do
    d = Discerner::ParameterValue.new(:name => 'new parameter value', 
      :database_name => parameter_value.database_name, 
      :parameter => parameter_value.parameter,
      :deleted_at => Time.now)
    d.should_not be_valid
    
    Factory.create(:parameter_value, :name => 'deleted parameter value', 
      :database_name => 'deleted_parameter_value',
      :parameter => parameter_value.parameter,
      :deleted_at => Time.now)
      
    d = Discerner::ParameterValue.new(:name => 'deleted parameter', 
      :database_name => 'deleted_parameter_value',
      :parameter => parameter_value.parameter)
    d.should_not be_valid
    
    d.deleted_at = Time.now
    d.should_not be_valid
  end
end
