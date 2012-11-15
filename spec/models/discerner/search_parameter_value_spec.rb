require 'spec_helper'

describe Discerner::SearchParameterValue do
  let!(:search_parameter_value) { 
    s = Factory.build(:search)
    s.search_parameters << Factory.build(:search_parameter, :search => s)
    s.save!
    Factory.build(:search_parameter_value, :search_parameter => s.search_parameters.first)
  }
  
  it "is valid with valid attributes" do
    search_parameter_value.should be_valid
  end
  
  it "allows to access matching search criteria" do
    search_parameter_value.should respond_to :search_parameter
  end
end
