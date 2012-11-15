require 'spec_helper'

describe Discerner::SearchParameter do
  let!(:search_parameter) { 
    s = Factory.build(:search)
    s.search_parameters << Factory.build(:search_parameter, :search => s)
    s.save!
    s.search_parameters.first
  }

  it "is valid with valid attributes" do
    search_parameter.should be_valid
  end
  
  it "allows to access matching search criteria values" do
    search_parameter.should respond_to :search_parameter_values
  end
  
  it "should accept attributes for search criteria values" do
    s = Discerner::SearchParameter.new( :search => Factory.build(:search), 
      :search_parameter_values_attributes => { "0" => { :operator => Factory.build(:operator), :parameter_value => Factory.build(:parameter_value, :parameter => Discerner::Parameter.last)}})
    s.should be_valid
    s.save
    s.should have(1).search_parameter_values
  end
  
end
