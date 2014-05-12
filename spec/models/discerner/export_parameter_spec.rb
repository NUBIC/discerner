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

  it "validates presence of parameter and search" do
    ep = Discerner::ExportParameter.new
    ep.should_not be_valid
    ep.errors.full_messages.should include('Search for export parameter can\'t be blank')
    ep.errors.full_messages.should include('Parameter for export parameter can\'t be blank')

    s = FactoryGirl.build(:search)
    ep = s.export_parameters.build(:parameter => Discerner::Parameter.last)
    ep.should be_valid
    ep.errors.should be_empty

    p = Discerner::Parameter.new(:name => 'new parameter', :unique_identifier => 'new_parameter')
    p.valid?
    puts p.errors.full_messages.inspect
    ep = p.export_parameters.build(:search => Discerner::Search.last)
    ep.should be_valid
    ep.errors.should be_empty
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
