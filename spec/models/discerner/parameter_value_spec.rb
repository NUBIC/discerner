require 'spec_helper'

describe Discerner::ParameterValue do
  let!(:parameter_value) { FactoryGirl.create(:parameter_value) }

  it "is valid with valid attributes" do
    expect(parameter_value).to be_valid
  end

  it "validates that parameter value has a name" do
    p = Discerner::ParameterValue.new()
    expect(p).not_to be_valid
    expect(p.errors.full_messages).to include 'Name can\'t be blank'
  end

  it "validates that parameter value belongs to a parameter" do
    p = Discerner::ParameterValue.new()
    expect(p).not_to be_valid
    expect(p.errors.full_messages).to include 'Parameter can\'t be blank'
  end

  it "validates uniqueness of search_value for not-deleted records" do
    p = Discerner::ParameterValue.new(:name => 'new parameter',
      :search_value => parameter_value.search_value,
      :parameter => parameter_value.parameter)

    expect(p).not_to be_valid
    expect(p.errors.full_messages).to include 'Search value for parameter value has already been taken'
  end

  it "does not allow to reuse search_value if record has been deleted" do
    p = Discerner::ParameterValue.new(:name => 'new parameter value',
      :search_value => parameter_value.search_value,
      :parameter => parameter_value.parameter)
    p.deleted_at = Time.now
    expect(p).not_to be_valid

    p1 = FactoryGirl.create(:parameter_value, :name => 'deleted parameter value',
      :search_value => 'deleted_parameter_value',
      :parameter => parameter_value.parameter)
    p1.deleted_at = Time.now
    p1.save

    p = Discerner::ParameterValue.new(:name => 'deleted parameter',
      :search_value => 'deleted_parameter_value',
      :parameter => parameter_value.parameter)
    expect(p).not_to be_valid

    p.deleted_at = Time.now
    expect(p).not_to be_valid
  end

  it "detects if record has been marked as deleted" do
    parameter_value.deleted_at = Time.now
    expect(parameter_value).to be_deleted
  end

  it "validates string_value length" do
    parameter_value.search_value = 'a'*5000
    expect(parameter_value).not_to be_valid
    expect(parameter_value.errors.full_messages).to include "Search value is too long (maximum is 1000 characters)"
  end

  it "validates name length" do
    parameter_value.name = 'a'*5000
    expect(parameter_value).not_to be_valid
    expect(parameter_value.errors.full_messages).to include "Name is too long (maximum is 1000 characters)"
  end

  it "detects if parameter value is used in search" do
    v = parameter_value
    p = v.parameter
    expect(v).not_to be_used_in_search

    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => p)
    s.save!

    spv = FactoryGirl.create(:search_parameter_value, :search_parameter => s.search_parameters.first, :parameter_value => v)
    expect(v.reload).to be_used_in_search

    p.parameter_type = FactoryGirl.create(:parameter_type, :name => 'list')
    p.save!

    expect(v.reload).not_to be_used_in_search

    spv.chosen = true
    spv.save
    expect(v.reload).to be_used_in_search
  end

  it "does not destroy linked search_parameter_values on soft delete if it is used in search " do
    v = parameter_value
    p = v.parameter
    s = FactoryGirl.build(:search)

    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => p)
    s.save!
    spv = FactoryGirl.create(:search_parameter_value, :search_parameter => s.search_parameters.first, :parameter_value => v)

    v.deleted_at = Time.now
    v.save
    expect(v).to be_deleted
    expect(spv.class).to exist(spv)
  end

  it "destroys linked search_parameter_values on soft delete if it is used in search but not chosen from 'list' parameter values" do
    v = parameter_value
    p = v.parameter
    p.parameter_type = FactoryGirl.create(:parameter_type, :name => 'list')
    p.save!

    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => p)
    s.save!
    spv = FactoryGirl.create(:search_parameter_value, :search_parameter => s.search_parameters.first, :parameter_value => v)

    v.deleted_at = Time.now
    v.save
    expect(v).to be_deleted
    expect(spv.class).not_to exist(spv)
  end

  it "destroys linked search_parameter_values on destroy" do
    v = parameter_value
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => v.parameter)
    s.save!
    spv = FactoryGirl.create(:search_parameter_value, :search_parameter => s.search_parameters.first, :parameter_value => v)

    v.destroy
    expect(v.class).not_to exist(v)
    expect(spv.class).not_to exist(spv)
  end

  it "creates additional search_parameter_values for list parameters" do
    v = parameter_value
    p = v.parameter
    p.parameter_type = FactoryGirl.build(:parameter_type, :name => 'list')
    p.save

    s = FactoryGirl.build(:search)
    sp = FactoryGirl.build(:search_parameter, :search => s, :parameter => v.parameter)
    spv = FactoryGirl.create(:search_parameter_value, :search_parameter => sp, :parameter_value => v)
    s.search_parameters << sp
    s.save!
    expect(sp.reload.search_parameter_values.length).to eq 1

    v1 = FactoryGirl.create(:parameter_value, :search_value => 'other value', :parameter => v.parameter)
    expect(v1).to be_valid
    expect(sp.reload.search_parameter_values.length).to eq 2
  end

  it "should allow to assign parameter value category" do
    expect(parameter_value).to respond_to(:parameter_value_category)
    parameter_value_category = FactoryGirl.create(:parameter_value_category, :parameter => parameter_value.parameter)
    parameter_value.parameter_value_category = parameter_value_category
    expect(parameter_value).to be_valid
  end

  it "should not allow to assign parameter value category that belongs to a different parameter" do
    expect(parameter_value).to respond_to(:parameter_value_category)
    parameter_value_category = FactoryGirl.create(:parameter_value_category, :parameter => FactoryGirl.create(:parameter, :unique_identifier => 'blah'))
    parameter_value.parameter_value_category = parameter_value_category
    expect(parameter_value).not_to be_valid
    expect(parameter_value.errors.full_messages).to include "Parameter category #{parameter_value_category.name} does not belong to parameter #{parameter_value_category.parameter.name}"
  end
end
