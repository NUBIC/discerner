require 'spec_helper'

describe Discerner::Dictionary do
  let!(:dictionary) { FactoryGirl.create(:dictionary) }

  it "is valid with valid attributes" do
    dictionary.should be_valid
  end

  it "validates that dictionary has a name" do
    c = Discerner::Dictionary.new()
    c.should_not be_valid
    c.errors.full_messages.should include 'Name can\'t be blank'
  end

  it "validates uniqueness of name for not-deleted records" do
    d = Discerner::Dictionary.new(:name => dictionary.name)
    d.should_not be_valid
    d.errors.full_messages.should include 'Name for dictionary has already been taken'
  end

  it "does not allow to reuse name if record has been deleted" do
    d = Discerner::Dictionary.new(:name => dictionary.name, :deleted_at => Time.now)
    d.should_not be_valid

    FactoryGirl.create(:dictionary, :name => 'deleted dictionary', :deleted_at => Time.now)
    d = Discerner::Dictionary.new(:name => 'deleted dictionary')
    d.should_not be_valid

    d.deleted_at = Time.now
    d.should_not be_valid
  end

  it "allows to access parameter_categories for dictionary" do
    dictionary.should respond_to :parameter_categories
  end

  it "detects if record has been marked as deleted" do
    dictionary.deleted_at = Time.now
    dictionary.should be_deleted
  end

  it "soft deleted linked parameter category on soft delete" do
    parameter_category = FactoryGirl.create(:parameter_category, :dictionary => dictionary)
    dictionary.deleted_at = Time.now
    dictionary.save
    parameter_category.reload.should be_deleted
  end
end