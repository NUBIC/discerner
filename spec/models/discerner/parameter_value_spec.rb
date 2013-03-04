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

  it "validates uniqueness of search_value for not-deleted records" do
    p = Discerner::ParameterValue.new(:name => 'new parameter',
      :search_value => parameter_value.search_value, 
      :parameter => parameter_value.parameter)
      
    p.should_not be_valid
    p.errors.full_messages.should include 'Search value for parameter value has already been taken'
  end
  
  it "does not allow to reuse search_value if record has been deleted" do
    d = Discerner::ParameterValue.new(:name => 'new parameter value', 
      :search_value => parameter_value.search_value, 
      :parameter => parameter_value.parameter,
      :deleted_at => Time.now)
    d.should_not be_valid
    
    Factory.create(:parameter_value, :name => 'deleted parameter value', 
      :search_value => 'deleted_parameter_value',
      :parameter => parameter_value.parameter,
      :deleted_at => Time.now)
      
    d = Discerner::ParameterValue.new(:name => 'deleted parameter', 
      :search_value => 'deleted_parameter_value',
      :parameter => parameter_value.parameter)
    d.should_not be_valid
    
    d.deleted_at = Time.now
    d.should_not be_valid
  end
  
  it "detects if record has been marked as deleted" do
    parameter_value.deleted_at = Time.now
    parameter_value.should be_deleted
  end
  
  it "validates string_value length" do
    parameter_value.search_value = 'a'*5000
    parameter_value.should_not be_valid
    parameter_value.errors.full_messages.should include "Search value is too long (maximum is 1000 characters)"
  end
  
  it "validates name length" do
    parameter_value.name = 'a'*5000
    parameter_value.should_not be_valid
    parameter_value.errors.full_messages.should include "Name is too long (maximum is 1000 characters)"
  end
  
  it "detects if parameter value is used in search" do
    v = parameter_value
    v.should_not be_used_in_search
    
    s = Factory.build(:search)
    s.search_parameters << Factory.build(:search_parameter, :search => s, :parameter => v.parameter)
    s.save!
    Factory.create(:search_parameter_value, :search_parameter => s.search_parameters.first, :parameter_value => v)
    v.reload.should be_used_in_search
  end
end
