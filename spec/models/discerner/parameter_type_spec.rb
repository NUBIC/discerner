require 'spec_helper'

describe Discerner::ParameterType do
  let!(:parameter_type) { FactoryGirl.create(:parameter_type) }

  it "is valid with valid attributes" do
    expect(parameter_type).to be_valid
  end

  it "validates that parameter type has a name" do
    d = Discerner::ParameterType.new()
    expect(d).to_not be_valid
    expect(d.errors.full_messages).to include 'Name can\'t be blank'
  end

  it "validates uniqueness of name for not-deleted records" do
    d = Discerner::ParameterType.new(name: parameter_type.name)
    expect(d).to_not be_valid
    expect(d.errors.full_messages).to include 'Name for parameter type has already been taken'
  end

  it "does not allow to reuse name if record has been deleted" do
    d = Discerner::ParameterType.new(name: parameter_type.name, deleted_at: Time.now)
    expect(d).to_not be_valid

    FactoryGirl.create(:parameter_type, name: 'numeric', deleted_at: Time.now)
    d = Discerner::ParameterType.new(name: 'numeric')
    expect(d).to_not be_valid

    d.deleted_at = Time.now
    expect(d).to_not be_valid
  end

  it "allows to access matching operators" do
    expect(parameter_type).to respond_to :operators
  end

  it "detects if record has been marked as deleted" do
    parameter_type.deleted_at = Time.now
    expect(parameter_type).to be_deleted
  end

  it "validates that parameter type is supported" do
    parameter_type.name = 'some type'
    expect(parameter_type).to_not be_valid
    expect(parameter_type.errors.full_messages).to include "Parameter type 'some type' is not supported, please use one of the following types: numeric, date, list, combobox, text, string, search, exclusive_list"
  end
end
