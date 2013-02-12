require 'spec_helper'

describe Discerner::ExportParameter do
  let!(:export_parameter) { 
    s = Factory.build(:search)
    s.export_parameters << Factory.build(:export_parameter, :search => s)
    s.search_parameters << Factory.build(:search_parameter, :search => s, :parameter => Discerner::Parameter.last)
    s.dictionary = Discerner::Dictionary.last
    s.save!
    s.export_parameters.first
  }

  it "is valid with valid attributes" do
    export_parameter.should be_valid
  end
end
