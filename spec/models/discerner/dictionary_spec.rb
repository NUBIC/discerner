require 'spec_helper'

describe Discerner::Dictionary do
  let!(:dictionary) { FactoryGirl.create(:dictionary) }

  it "is valid with valid attributes" do
    expect(dictionary).to be_valid
  end

  it "validates that dictionary has a name" do
    c = Discerner::Dictionary.new()
    expect(c).to_not be_valid
    expect(c.errors.full_messages).to include 'Name can\'t be blank'
  end

  it "validates uniqueness of name for not-deleted records" do
    d = Discerner::Dictionary.new(name: dictionary.name)
    expect(d).to_not be_valid
    expect(d.errors.full_messages).to include 'Name for dictionary has already been taken'
  end

  it "does not allow to reuse name if record has been deleted" do
    d = Discerner::Dictionary.new(name: dictionary.name, deleted_at: Time.now)
    expect(d).to_not be_valid

    FactoryGirl.create(:dictionary, name: 'deleted dictionary', deleted_at: Time.now)
    d = Discerner::Dictionary.new(name: 'deleted dictionary')
    expect(d).to_not be_valid

    d.deleted_at = Time.now
    expect(d).to_not be_valid
  end

  it "allows to access parameter_categories for dictionary" do
    expect(dictionary).to respond_to :parameter_categories
  end

  it "detects if record has been marked as deleted" do
    dictionary.deleted_at = Time.now
    expect(dictionary).to be_deleted
  end

  it "soft deleted linked parameter category on soft delete" do
    parameter_category = FactoryGirl.create(:parameter_category, dictionary: dictionary)
    dictionary.deleted_at = Time.now
    dictionary.save
    expect(parameter_category.reload).to be_deleted
  end

  it "allows to namespace dictionaries" do
    d1 = FactoryGirl.create(:dictionary, :namespace_type => 'Encounter', name: 'Encounter')
    d2 = FactoryGirl.create(:dictionary, :namespace_type => 'EncounterNote', name: 'EncounterNote')
    expect(Discerner::Dictionary.where(:namespace_type => 'Encounter').length).to eq 1
  end
end