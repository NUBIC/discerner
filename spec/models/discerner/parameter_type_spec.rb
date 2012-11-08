require 'spec_helper'

describe Discerner::ParameterType do
  let!(:parameter_type) { Factory.create(:parameter_type) }

  it "is valid with valid attributes" do
    parameter_type.should be_valid
  end
  
  it "validates that parameter type has a name" do
    d = Discerner::ParameterType.new()
    d.should_not be_valid
    d.errors.full_messages.should include 'Name can\'t be blank'
  end
  
  it "validates uniqueness of name for not-deleted records" do
    d = Discerner::ParameterType.new(:name => parameter_type.name)
    d.should_not be_valid
    d.errors.full_messages.should include 'Name for parameter type has already been taken'
  end
  
  it "does not allow to reuse name if record has been deleted" do
    d = Discerner::ParameterType.new(:name => parameter_type.name, :deleted_at => Time.now)
    d.should_not be_valid
    
    Factory.create(:parameter_type, :name => 'deleted', :deleted_at => Time.now)
    d = Discerner::ParameterType.new(:name => 'deleted')
    d.should_not be_valid
    
    d.deleted_at = Time.now
    d.should_not be_valid
  end
  
  it "allows to access matching operators" do
    parameter_type.should respond_to :operators
  end
  
  it "detects if record has been marked as deleted" do
    parameter_type.deleted_at = Time.now
    parameter_type.should be_deleted
  end
end
