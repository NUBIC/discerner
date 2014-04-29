require 'spec_helper'

describe Discerner::SearchCombination do
  let!(:search) {
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s)
    s.dictionary = Discerner::Dictionary.last
    s.save!
    s
  }

  let!(:search_combination) {
    s = FactoryGirl.build(:search, :name => 'other search')
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => FactoryGirl.create(:parameter, :unique_identifier => 'other_search_parameter', :search_model => 'A', :search_method => 'A', :parameter_type => Discerner::ParameterType.last || FactoryGirl.build(:parameter_type) ))
    FactoryGirl.create(:search_parameter_value, :search_parameter => s.search_parameters.first, :value => '0', :operator => FactoryGirl.create(:operator, :symbol => '<', :text => 'is less than'))
    s.save!
    FactoryGirl.create(:search_combination, :search => search, :combined_search => s)
  }
  it "is valid with valid attributes" do
    search_combination.should be_valid
  end

  it "allows to access parent search" do
    search_combination.should respond_to :search
  end

  it "allows to access combined search" do
    search_combination.should respond_to :combined_search
  end

  it "should not allow to combine search with itself" do
    c = Discerner::SearchCombination.new(:search => search, :combined_search => search)
    c.should_not be_valid
  end

  it "should disable combinations with deleted searches" do
    search_combination.should_not be_disabled
    search_combination.combined_search.deleted_at = Time.now
    search_combination.should be_disabled
  end

  it "should disable combinations with disabled searches" do
    search_combination.should_not be_disabled
    search_combination.combined_search.dictionary.deleted_at = Time.now
    search_combination.should be_disabled
  end
end
