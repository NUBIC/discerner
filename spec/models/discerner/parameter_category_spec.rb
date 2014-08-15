require 'spec_helper'

describe Discerner::ParameterCategory do
  let!(:parameter_category) { FactoryGirl.create(:parameter_category) }

  it "is valid with valid attributes" do
    expect(parameter_category).to be_valid
  end

  it "validates that category belongs to a dictionary" do
    c = Discerner::ParameterCategory.new(:name => parameter_category.name)
    expect(c).to_not be_valid
    expect(c.errors.full_messages).to include 'Dictionary for parameter category can\'t be blank'
  end

  it "validates that category has a name" do
    c = Discerner::ParameterCategory.new(:dictionary => parameter_category.dictionary)
    expect(c).to_not be_valid
    expect(c.errors.full_messages).to include 'Name can\'t be blank'
  end

  it "validates uniqueness of name for not-deleted records in the same dictionary" do
    c = Discerner::ParameterCategory.new(:name => parameter_category.name, :dictionary => parameter_category.dictionary)
    expect(c).to_not be_valid
    expect(c.errors.full_messages).to include 'Name for parameter category has already been taken'
  end

  it "does not allow to reuse name if record has been deleted" do
    c = Discerner::ParameterCategory.new(:name => parameter_category.name, :dictionary => parameter_category.dictionary, :deleted_at => Time.now)
    expect(c).to_not be_valid

    FactoryGirl.create(:parameter_category, :name => 'deleted parameter_category', :dictionary => parameter_category.dictionary, :deleted_at => Time.now)
    d = Discerner::ParameterCategory.new(:name => 'deleted parameter_category', :dictionary => parameter_category.dictionary)
    expect(d).to_not be_valid

    d.deleted_at = Time.now
    expect(d).to_not be_valid
  end

  it "allows to reuse name from different dictionary" do
    c = Discerner::ParameterCategory.new(:name => parameter_category.name, :dictionary => FactoryGirl.create(:dictionary, :name => "even better dictionary"))
    expect(c).to be_valid
  end

  it "allows to access dictionary from parameter_category" do
    expect(parameter_category).to respond_to :dictionary
  end

  it "detects if record has been marked as deleted" do
    parameter_category.deleted_at = Time.now
    expect(parameter_category).to be_deleted
  end

  it "soft deletes linked parameters on soft delete" do
    parameter = FactoryGirl.create(:parameter, :parameter_category => parameter_category)
    parameter_category.deleted_at = Time.now
    parameter_category.save
    expect(parameter.reload).to be_deleted
  end
end
