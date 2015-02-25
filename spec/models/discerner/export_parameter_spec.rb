require 'spec_helper'

describe Discerner::ExportParameter do
  let!(:export_parameter) {
    s = FactoryGirl.build(:search)
    s.export_parameters << FactoryGirl.build(:export_parameter, search: s)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: Discerner::Parameter.last)
    s.dictionary = Discerner::Dictionary.last
    s.save!
    s.export_parameters.first
  }

  it "is valid with valid attributes" do
    expect(export_parameter).to be_valid
  end

  it "validates presence of parameter and search" do
    ep = Discerner::ExportParameter.new
    expect(ep).to_not be_valid
    expect(ep.errors.full_messages).to include('Search for export parameter can\'t be blank')
    expect(ep.errors.full_messages).to include('Parameter for export parameter can\'t be blank')

    s = FactoryGirl.build(:search)
    ep = s.export_parameters.build(parameter: Discerner::Parameter.last)
    expect(ep).to be_valid
    expect(ep.errors).to be_empty

    p = Discerner::Parameter.new(name: 'new parameter', unique_identifier: 'new_parameter')
    p.valid?
    puts p.errors.full_messages.inspect
    ep = p.export_parameters.build(search: Discerner::Search.last)
    expect(ep).to be_valid
    expect(ep.errors).to be_empty
  end

  it "disables export parameter if it uses deleted parameter" do
    expect(export_parameter).to_not be_disabled
    export_parameter.parameter.deleted_at = Time.now
    expect(export_parameter).to be_disabled
  end

  it "disables export parameter if it is deleted" do
    expect(export_parameter).to_not be_disabled
    export_parameter.deleted_at = Time.now
    expect(export_parameter).to be_disabled
  end

  it "filters ecport paraeters by parameter category" do
    pc = export_parameter.parameter.parameter_category
    expect(pc).to_not be_blank
    expect(Discerner::ExportParameter.by_parameter_category(pc)).to_not be_blank
    expect(Discerner::ExportParameter.by_parameter_category(pc)).to include(export_parameter)

    pc = FactoryGirl.create(:parameter_category, name: 'another category')
    expect(pc).to_not be_blank
    expect(Discerner::ExportParameter.by_parameter_category(pc)).to be_blank
  end
end
