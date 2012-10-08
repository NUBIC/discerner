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
  
  it "validates that parameter belongs to a parameter_group" do
    p = Discerner::Parameter.new()
    p.should_not be_valid
    p.errors.full_messages.should include 'Parameter category can\'t be blank'
  end
  
  it "validates uniqueness of database_name for not-deleted records" do
    p = Discerner::Parameter.new(:name => 'new parameter',
      :database_name => parameter.database_name, 
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type)
      
    p.should_not be_valid
    p.errors.full_messages.should include 'Database name has already been taken'
  end
  
  it "allows to reuse database_name if record has been deleted" do
    d = Discerner::Parameter.new(:name => 'new parameter', 
      :database_name => parameter.database_name, 
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type,
      :deleted_at => Time.now)
    d.should be_valid
    
    Factory.create(:parameter, :name => 'deleted parameter', 
      :database_name => 'deleted_parameter',
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type,
      :deleted_at => Time.now)
    d = Discerner::Parameter.new(:name => 'deleted parameter', 
      :database_name => 'deleted_parameter',
      :parameter_category => parameter.parameter_category,
      :parameter_type => parameter.parameter_type)
    d.should be_valid
    
    d.deleted_at = Time.now
    d.should be_valid
  end

  it "allows to access parameter category" do
    parameter.should respond_to :parameter_category
  end

  it "allows to access parameter type" do
    parameter.should respond_to :parameter_type
  end

end
