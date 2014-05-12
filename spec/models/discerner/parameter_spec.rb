require 'spec_helper'

describe Discerner::Parameter do
  let(:parameter) { FactoryGirl.create(:parameter) }

  it "is valid with valid attributes" do
    parameter.should be_valid
  end

  it "validates that parameter has a name" do
    p = Discerner::Parameter.new()
    p.should_not be_valid
    p.errors.full_messages.should include 'Name for parameter can\'t be blank'
  end

  it "validates that parameter belongs to a parameter category" do
    p = Discerner::Parameter.new()
    p.should_not be_valid
    p.errors.full_messages.should include 'Parameter category for parameter can\'t be blank'
  end

  it "validates that searchable parameter has parameter type, model and attribute" do
    p = FactoryGirl.build(:parameter, :search_model => 'A')
    p.should_not be_valid
    p.errors.full_messages.should include 'Searchable parameter should have search model, search method and parameter_type defined.'

    p = FactoryGirl.build(:parameter, :search_method => 'A')
    p.should_not be_valid
    p.errors.full_messages.should include 'Searchable parameter should have search model, search method and parameter_type defined.'

    p = FactoryGirl.build(:parameter, :search_model => 'A', :search_method => 'A')
    p.parameter_type = nil
    p.should_not be_valid
    p.errors.full_messages.should include 'Searchable parameter should have search model, search method and parameter_type defined.'

    p = FactoryGirl.build(:parameter, :search_model => 'A', :search_method => 'A', :parameter_type => Discerner::ParameterType.last || FactoryGirl.build(:parameter_type) )
    p.should be_valid
  end

  it "validates uniqueness of unique_identifier" do
    p1 = parameter
    p = Discerner::Parameter.new(:name => 'new parameter',
      :unique_identifier => p1.unique_identifier,
      :parameter_category => p1.parameter_category)

    p.should_not be_valid
    p.errors.full_messages.should include 'Unique identifier has to be unique within dictionary.'
  end

  it "allows to re-use unique_identifier in different dictionary" do
    p = Discerner::Parameter.new(:name => 'new parameter',
      :unique_identifier => parameter.unique_identifier,
      :parameter_category => FactoryGirl.create(:parameter_category, :name => 'other category', :dictionary => FactoryGirl.create(:dictionary, :name => "other dictionary")))
    p.should be_valid
  end

  it "does not allow to reuse unique_identifier if record has been deleted" do
    d = Discerner::Parameter.new(:name => 'new parameter',
      :unique_identifier => parameter.unique_identifier,
      :parameter_category => parameter.parameter_category)
    d.deleted_at = Time.now
    d.should_not be_valid

    d1 = FactoryGirl.create(:parameter, :name => 'deleted parameter',
      :unique_identifier => 'deleted_unique_identifier',
      :parameter_category => parameter.parameter_category)
    d1.deleted_at = Time.now

    d = Discerner::Parameter.new(:name => 'deleted parameter',
      :unique_identifier => 'deleted_unique_identifier',
      :parameter_category => parameter.parameter_category)
    d.should_not be_valid

    d.deleted_at = Time.now
    d.should_not be_valid
  end

  it "allows to access parameter values if exist" do
    parameter_value = FactoryGirl.create(:parameter_value, :parameter => parameter)

    parameter = Discerner::Parameter.last
    parameter.parameter_values.length.should == 1
    parameter.parameter_values.first.id.should == parameter_value.id
  end

  it "detects if record has been marked as deleted" do
    parameter.deleted_at = Time.now
    parameter.should be_deleted
  end

  it "detects if parameter is used in search through search parameters" do
    p = parameter
    p.should_not be_used_in_search

    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => p)
    s.save!
    p.reload.should be_used_in_search
  end

  it "detects if parameter is used in search through export parameters" do
    p = parameter
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => Discerner::Parameter.last)
    s.export_parameters << FactoryGirl.build(:export_parameter, :search => s, :parameter => p)
    s.dictionary = Discerner::Dictionary.last
    s.save!

    p.reload.should be_used_in_search
  end

  it "soft deletes linked parameter_values on soft delete" do
    p = parameter
    parameter_value = FactoryGirl.create(:parameter_value, :parameter => p)

    p.deleted_at = Time.now
    p.save
    p.reload.should be_deleted
  end
end
