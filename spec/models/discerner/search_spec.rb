require 'spec_helper'

describe Discerner::Search do
  let!(:search) {
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s)
    s.dictionary = Discerner::Dictionary.last
    s.save!
    s
  }

  let(:search_combination) {
    s = FactoryGirl.build(:search, name: 'other search')
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: FactoryGirl.build(:parameter, search_method: 'other_parameter'))
    s.save!
    c = Discerner::SearchCombination.new(search: search, combined_search: s)
    c.save!
    c
  }

  it "is valid with valid attributes" do
    expect(search).to be_valid
  end

  it "validates that search belongs to a dictionary" do
    s = Discerner::Search.new()
    expect(s).to_not be_valid
    expect(s.errors.full_messages).to include 'Dictionary for search can\'t be blank'
  end

  it "validates that search has at least one search criteria" do
    s = Discerner::Search.new()
    expect(s).to_not be_valid
    expect(s.errors.full_messages).to include 'Search should have at least one search criteria.'
  end

  it "should accept attributes for search criterias" do
    s = Discerner::Search.new( username: 'me', search_parameters_attributes: { "0"=> { parameter: Discerner::Parameter.last}}, dictionary: Discerner::Dictionary.last)
    expect(s).to be_valid
    s.save
    expect(s.search_parameters.length).to eq 1
  end

  it "does not force that search has a username" do
    s = Discerner::Search.new(search_parameters_attributes: { "0" => { parameter: Discerner::Parameter.last}})
    s.dictionary = Discerner::Dictionary.last
    expect(s).to be_valid
    expect(s.errors.full_messages).to_not include 'Username can\'t be blank'
  end

  it "allows to access combined searches" do
    c = search_combination
    expect(search.reload.combined_searches.length).to eq 1
  end

  it "populates conditions" do
    s = Discerner::Search.new(search_parameters_attributes: { "0" => { parameter: Discerner::Parameter.last}})
    s.dictionary = Discerner::Dictionary.last
    expect(s).to be_valid
    expect(s.conditions).to_not be_blank
  end

  it "returns search conditions grouped by search model" do
    p1 = FactoryGirl.create(:parameter, unique_identifier: 'param_one', search_model: 'Patient', search_method: 'age_at_case_collect', parameter_type: FactoryGirl.create(:parameter_type, name: 'numeric'))
    p2 = FactoryGirl.create(:parameter, unique_identifier: 'param_two', search_model: 'Patient', search_method: 'having_gender', parameter_type: FactoryGirl.create(:parameter_type, name: 'list'))
    p3 = FactoryGirl.create(:parameter, unique_identifier: 'param_three', search_model: 'Case', search_method: 'accessioned_dt_tm', parameter_type: FactoryGirl.create(:parameter_type, name: 'date'))

    [['is less than','<','comparison'], ['is equal to','=','comparison'], ['is like','is like','text_comparison'], ['is in the range','between','range'], ['none', 'is null','presence']].each do |o|
      FactoryGirl.create(:operator, text: o[0], symbol: o[1], operator_type: o[2])
    end

    s1 = FactoryGirl.build(:search)
    sp11 = s1.search_parameters.build(parameter: p1)
    sp12 = s1.search_parameters.build(parameter: p3)

    sp11.search_parameter_values.build(operator: Discerner::Operator.find_by_symbol('<'), value: '50')
    sp11.search_parameter_values.build(operator: Discerner::Operator.find_by_symbol('='), value: '65')
    sp11.search_parameter_values.build(operator: Discerner::Operator.find_by_symbol('between'), value: '75', additional_value: '80')

    sp12.search_parameter_values.build(operator: Discerner::Operator.find_by_symbol('between'), value: '01/02/2009', additional_value: '02/02/2009')
    sp12.search_parameter_values.build(operator: Discerner::Operator.find_by_symbol('='), value: '03/05/2009')
    sp12.search_parameter_values.build(operator: Discerner::Operator.find_by_symbol('is null'))

    s1.save!

    s2 = FactoryGirl.build(:search)
    sp2 = s2.search_parameters.build(parameter: p2)
    sp2.search_parameter_values.build(parameter_value: FactoryGirl.create(:parameter_value, name: 'Male', search_value: 'male', parameter: p2), chosen: true)
    sp2.search_parameter_values.build(parameter_value: FactoryGirl.create(:parameter_value, name: 'Female', search_value: 'female', parameter: p2), chosen: false)
    s2.combined_searches << s1
    s2.save!

    expect(s2.to_conditions).to_not be_blank
    expect(s2.to_conditions['Case']).to_not be_blank
    expect(s2.to_conditions['Case'][:search_parameters].length).to eq 1
    expect(s2.to_conditions['Case'][:conditions]).to include("(accessioned_dt_tm between ? and ? or accessioned_dt_tm = ? or accessioned_dt_tm is null)")
    expect(s2.to_conditions['Case'][:conditions]).to include('01/02/2009'.to_date)
    expect(s2.to_conditions['Case'][:conditions]).to include('02/02/2009'.to_date)
    expect(s2.to_conditions['Case'][:conditions]).to include('03/05/2009'.to_date)
    expect(s2.to_conditions['Case'][:conditions]).to_not include(nil)

    expect(s2.to_conditions['Patient']).to_not be_blank
    expect(s2.to_conditions['Patient'][:search_parameters].length).to eq 2
    expect(s2.to_conditions['Patient'][:conditions]).to include("(age_at_case_collect < ? or age_at_case_collect = ? or age_at_case_collect between ? and ?) and patients.gender in (?)")
    expect(s2.to_conditions['Patient'][:conditions]).to include(50.0)
    expect(s2.to_conditions['Patient'][:conditions]).to include(65.0)
    expect(s2.to_conditions['Patient'][:conditions]).to include(75.0)
    expect(s2.to_conditions['Patient'][:conditions]).to include(80.0)
    expect(s2.to_conditions['Patient'][:conditions]).to include(['male'])
    expect(s2.to_conditions['Patient'][:conditions]).to_not include(['female'])

    expect(s2.to_conditions['Surgery']).to be_blank
  end

  describe "it soft deletes associated records" do
    it "soft deletes search parameters" do
      search.deleted_at = Time.now
      search.save
      expect(search.reload.search_parameters).to_not be_empty
      search.search_parameters.each do |sp|
        expect(sp).to be_deleted
      end
    end

    it "soft deletes export parameters" do
      FactoryGirl.create(:export_parameter, parameter: search.search_parameters.first.parameter, search: search)
      search.deleted_at = Time.now
      search.save
      expect(search.reload.export_parameters).to_not be_empty
      search.export_parameters.each do |sp|
        expect(sp).to be_deleted
      end
    end

    it "soft deletes search combinations" do
      c = search_combination
      search.deleted_at = Time.now
      search.save
      expect(search.reload.search_combinations).to_not be_empty
      search.search_combinations.each do |sc|
        expect(sc).to be_deleted
      end
    end
  end

  describe "it detects if search is disabled" do
    before(:each) do
      FactoryGirl.create(:search_parameter_value, search_parameter: search.search_parameters.first, value: '0', operator: FactoryGirl.create(:operator, symbol: '<', text: 'is less than'))
    end

    it "disables search on deleted dictionary" do
      expect(search).to_not be_disabled
      search.dictionary.deleted_at = Time.now
      expect(search).to be_disabled
    end

    it "disables search with disabled search parameter" do
      expect(search).to_not be_disabled
      search.search_parameters.first.parameter.deleted_at = Time.now
      expect(search).to be_disabled
    end

    it "disables search with disabled export parameter" do
      FactoryGirl.create(:export_parameter, parameter: search.search_parameters.first.parameter, search: search)
      expect(search).to_not be_disabled

      search.export_parameters.first.parameter.deleted_at = Time.now
      expect(search).to be_disabled
    end
  end

  it "detects if model have been used in search" do
    p = FactoryGirl.create(:parameter, unique_identifier: 'param_one', search_model: 'Patient', search_method: 'age_at_case_collect', parameter_type: FactoryGirl.create(:parameter_type, name: 'numeric'))
    s = FactoryGirl.build(:search)
    sp = s.search_parameters.build(parameter: p)

    expect(s.searched_model?('Patient')).to eq true
    expect(s.searched_model?('Surgery')).to eq false
  end

  it "calls to_conditions only when conditions are not set or are called directly" do
    p = FactoryGirl.create(:parameter, unique_identifier: 'param_one', search_model: 'Patient', search_method: 'age_at_case_collect', parameter_type: FactoryGirl.create(:parameter_type, name: 'numeric'))
    s = FactoryGirl.build(:search)
    expect(s).to receive(:to_conditions).once.and_return({hello: 'world'})

    sp = s.search_parameters.build(parameter: p)
    s.conditions
    s.save
    s.searched_model?('Patient')
    s.searched_model?('Surgery')
  end

  it "allows to namespace searches" do
    s1 = FactoryGirl.build(:search, :namespace_type => 'Neurology')
    s1.search_parameters << FactoryGirl.build(:search_parameter, search: s1, parameter: FactoryGirl.build(:parameter, search_method: 'yet_another_parameter'))

    s1.dictionary = Discerner::Dictionary.last
    s1.save!

    s2 = FactoryGirl.build(:search, :namespace_type => 'LynnSage')
    s2.search_parameters << FactoryGirl.build(:search_parameter, search: s2, parameter: FactoryGirl.build(:parameter, search_method: 'and_other_parameter'))
    s2.dictionary = Discerner::Dictionary.last
    s2.save!

    expect(Discerner::Search.where(:namespace_type => 'LynnSage').length).to eq 1
  end
end
