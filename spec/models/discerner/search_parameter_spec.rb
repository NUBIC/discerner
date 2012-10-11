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
end
