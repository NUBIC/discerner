require 'spec_helper'

describe Discerner::Search do
  let!(:search) { 
    s = Factory.build(:search)
    s.search_parameters << Factory.build(:search_parameter, :search => s)
    s.dictionary = Discerner::Dictionary.last
    s.save!
    s
  }
  
  let!(:search_combination) { 
    s = Factory.build(:search, :name => 'other search')
    s.search_parameters << Factory.build(:search_parameter, :search => s, :parameter => Factory.build(:parameter, :search_method => 'other_parameter'))
    s.save!
    Discerner::SearchCombination.new(:search => search, :combined_search => s)
  }
  
  it "is valid with valid attributes" do
    search.should be_valid
  end
  
  it "validates that search belongs to a dictionary" do
    s = Discerner::Search.new()
    s.should_not be_valid
    s.errors.full_messages.should include 'Dictionary for search can\'t be blank'
  end
  
  it "validates that search has at least one search criteria" do
    s = Discerner::Search.new()
    s.should_not be_valid
    s.errors.full_messages.should include 'Search should have at least one search criteria.'
  end
  
  it "should accept attributes for search criterias" do
    s = Discerner::Search.new( :username => 'me', :search_parameters_attributes => { "0" => { :parameter => Discerner::Parameter.last}}, :dictionary => Discerner::Dictionary.last)
    s.should be_valid
    s.save
    s.should have(1).search_parameters
  end
  
  it "does not force that search has a username" do
    s = Discerner::Search.new(:search_parameters_attributes => { "0" => { :parameter => Discerner::Parameter.last}})
    s.dictionary = Discerner::Dictionary.last
    s.should be_valid
    s.errors.full_messages.should_not include 'Username can\'t be blank'
  end
  
  it "allows to access combined searches" do
    c = search_combination
    c.save!
    search.reload.combined_searches.length.should == 1
  end
  
  it "returns search conditions grouped by search model" do
    p1 = Factory.create(:parameter, :unique_identifier => 'param_one', :search_model => 'Patient', :search_method => 'age_at_case_collect', :parameter_type => Factory.create(:parameter_type, :name => 'numeric'))
    p2 = Factory.create(:parameter, :unique_identifier => 'param_two', :search_model => 'Patient', :search_method => 'having_gender', :parameter_type => Factory.create(:parameter_type, :name => 'list'))
    p3 = Factory.create(:parameter, :unique_identifier => 'param_three', :search_model => 'Case', :search_method => 'accessioned_dt_tm', :parameter_type => Factory.create(:parameter_type, :name => 'date'))
    
    [['is less than','<'], ['is equal to', '='], ['is like','is like'], ['is in the range', 'between']].each do |o|
      Factory.create(:operator, :symbol => o.last, :text => o.first)
    end
        
    s = Factory.build(:search)
    sp1 = s.search_parameters.build(:parameter => p1)
    sp2 = s.search_parameters.build(:parameter => p2)
    sp3 = s.search_parameters.build(:parameter => p3)
    
    sp1.search_parameter_values.build(:operator => Discerner::Operator.find_by_symbol('<'), :value => '50')
    sp1.search_parameter_values.build(:operator => Discerner::Operator.find_by_symbol('='), :value => '65')
    sp1.search_parameter_values.build(:operator => Discerner::Operator.find_by_symbol('between'), :value => '75', :additional_value => '80')

    sp2.search_parameter_values.build(:parameter_value => Factory.create(:parameter_value, :name => 'Male', :search_value => 'male', :parameter => p2), :chosen => true)
    sp2.search_parameter_values.build(:parameter_value => Factory.create(:parameter_value, :name => 'Female', :search_value => 'female', :parameter => p2), :chosen => false)
    
    sp3.search_parameter_values.build(:operator => Discerner::Operator.find_by_symbol('between'), :value => '01/02/2009', :additional_value => '02/02/2009')
    sp3.search_parameter_values.build(:operator => Discerner::Operator.find_by_symbol('='), :value => '03/05/2009')
    
    s.save!

    s.to_conditions.should_not be_blank
    s.to_conditions['Case'].should_not be_blank
    s.to_conditions['Case'][:search_parameters].length.should == 1
    s.to_conditions['Case'][:conditions].should include("(accessioned_dt_tm between ? and ? or accessioned_dt_tm = ?)")
    s.to_conditions['Case'][:conditions].should include('01/02/2009'.to_date)
    s.to_conditions['Case'][:conditions].should include('02/02/2009'.to_date)
    s.to_conditions['Case'][:conditions].should include('03/05/2009'.to_date)
    
    s.to_conditions['Patient'].should_not be_blank
    s.to_conditions['Patient'][:search_parameters].length.should == 2
    s.to_conditions['Patient'][:conditions].should include("(age_at_case_collect < ? or age_at_case_collect = ? or age_at_case_collect between ? and ?) and patients.gender in (?)")
    s.to_conditions['Patient'][:conditions].should include(50.0)
    s.to_conditions['Patient'][:conditions].should include(65.0)
    s.to_conditions['Patient'][:conditions].should include(75.0)
    s.to_conditions['Patient'][:conditions].should include(80.0)
    s.to_conditions['Patient'][:conditions].should include(['male'])
    s.to_conditions['Patient'][:conditions].should_not include(['female'])
    
    s.to_conditions['Surgery'].should be_blank
  end
end
