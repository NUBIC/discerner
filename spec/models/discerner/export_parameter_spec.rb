require 'spec_helper'

describe Discerner::ExportParameter do
  let!(:export_parameter) {
    s = FactoryGirl.build(:search)
    s.export_parameters << FactoryGirl.build(:export_parameter, :search => s)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => Discerner::Parameter.last)
    s.dictionary = Discerner::Dictionary.last
    s.save!
    s.export_parameters.first
  }

  it "is valid with valid attributes" do
    export_parameter.should be_valid
  end

  it "disables export parameter if it uses deleted parameter" do
    export_parameter.should_not be_disabled
    export_parameter.parameter.deleted_at = Time.now
    export_parameter.should be_disabled
  end

  it "disables export parameter if it is deleted" do
    export_parameter.should_not be_disabled
    export_parameter.deleted_at = Time.now
    export_parameter.should be_disabled
  end
end
