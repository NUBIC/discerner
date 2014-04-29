require 'spec_helper'

describe Discerner::SearchParameter do
  let!(:search_parameter) {
    s = FactoryGirl.build(:search)
    search_parameter = FactoryGirl.build(:search_parameter, :search => s)
    search_parameter.parameter.parameter_type = FactoryGirl.build(:parameter_type, :name => 'numeric')
    s.search_parameters << search_parameter
    s.dictionary = Discerner::Dictionary.last
    s.save!
    s.search_parameters.first
  }

  it "is valid with valid attributes" do
    search_parameter.should be_valid
  end

  it "allows to access matching search parameter values" do
    search_parameter.should respond_to :search_parameter_values
  end

  it "should accept attributes for search parameter values" do
    s = Discerner::SearchParameter.new( :search => FactoryGirl.build(:search),
      :search_parameter_values_attributes => { "0" => { :operator => FactoryGirl.build(:operator), :parameter_value => FactoryGirl.build(:parameter_value, :parameter => Discerner::Parameter.last)}})
    s.should be_valid
    s.save
    s.should have(1).search_parameter_values
  end

  it "should not throw error if 'to_sql' is called on parameter without search model" do
    lambda {search_parameter.to_sql}.should_not raise_error
  end

  it "should not throw error if 'to_sql' is called on parameter without search model" do
    search_parameter.parameter.search_model   = 'Surgery'
    search_parameter.parameter.search_method  = 'id'
    lambda {search_parameter.to_sql}.should raise_error(RuntimeError, /could not be found/)
  end

  describe 'using attribute-based parameters' do
    it "should allow to convert 'numeric' search parameter to sql" do
      parameter = search_parameter.parameter
      parameter.search_model   = 'Patient'
      parameter.search_method  = 'age_at_case_collect'
      parameter.save!
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :value => '50', :operator => FactoryGirl.create(:operator, :symbol => '<', :text => 'is less than'))
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :value => '60', :additional_value => '70', :operator => FactoryGirl.create(:operator, :symbol => 'between', :text => 'is in the range', :operator_type => 'range'))
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :operator => FactoryGirl.create(:operator, :symbol => 'is null', :text => 'none', :operator_type => 'presence'))
      search_parameter.to_sql.should_not == {}
      search_parameter.to_sql[:predicates].should == "(age_at_case_collect < ? or age_at_case_collect between ? and ? or age_at_case_collect is null)"
      search_parameter.to_sql[:values].should    ==  [50.0, 60.0, 70.0]
    end

    it "should allow to convert 'date' search parameter to sql" do
      parameter = search_parameter.parameter
      parameter.search_model   = 'Patient'
      parameter.search_method  = 'age_at_case_collect'
      parameter.parameter_type = FactoryGirl.build(:parameter_type, :name => 'date')
      parameter.save!
      date1 = '01/02/2009'
      date2 = '02/03/2009'
      date3 = '02/04/2009'
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :value => date1, :operator => FactoryGirl.create(:operator, :symbol => '<', :text => 'is less than'))
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :value => date2, :additional_value => date3, :operator => FactoryGirl.create(:operator, :symbol => 'between', :text => 'is in the range', :operator_type => 'range'))
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :operator => FactoryGirl.create(:operator, :symbol => 'is null', :text => 'none', :operator_type => 'presence'))
      search_parameter.to_sql.should_not == {}
      search_parameter.to_sql[:predicates].should == "(age_at_case_collect < ? or age_at_case_collect between ? and ? or age_at_case_collect is null)"
      search_parameter.to_sql[:values].should    ==  [date1.to_date, date2.to_date, date3.to_date]
    end

    it "should allow to convert 'text' and 'string' search parameter to sql" do
      parameter = search_parameter.parameter
      parameter.search_model   = 'Patient'
      parameter.search_method  = 'age_at_case_collect'
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :value => 'first string',  :operator => FactoryGirl.create(:operator, :symbol => 'is like', :text => 'is like', :operator_type => 'text_comparison'))
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :value => 'second string', :operator => FactoryGirl.create(:operator, :symbol => 'is not like', :text => 'is not like', :operator_type => 'text_comparison'))
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :operator => FactoryGirl.create(:operator, :symbol => 'is null', :text => 'none', :operator_type => 'presence'))
      ['text', 'string'].each do |type|
        parameter.parameter_type = Discerner::ParameterType.find_by_name(type) || FactoryGirl.build(:parameter_type, :name => type)
        parameter.save!
        search_parameter.to_sql.should_not == {}
        search_parameter.to_sql[:predicates].should == "(age_at_case_collect is like ? or age_at_case_collect is not like ? or age_at_case_collect is null)"
        search_parameter.to_sql[:values].should    ==  ['%first string%', '%second string%']
      end
    end

    it "should allow to convert 'combobox' search parameter to sql" do
      parameter = search_parameter.parameter
      parameter.search_model   = 'Patient'
      parameter.search_method  = 'age_at_case_collect'
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :operator => nil, :parameter_value => FactoryGirl.create(:parameter_value, :name => 'first value', :search_value => 'first_value', :parameter => parameter) )
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :operator => nil, :parameter_value => FactoryGirl.create(:parameter_value, :name => 'another value', :search_value => 'another_value', :parameter => parameter) )

      parameter.parameter_type = FactoryGirl.build(:parameter_type, :name => 'combobox')
      parameter.save!
      search_parameter.to_sql.should_not == {}
      search_parameter.to_sql[:predicates].should == "age_at_case_collect in (?)"
      search_parameter.to_sql[:values].should    ==  [['first_value', 'another_value']]
    end

    it "should allow to convert 'list' search parameter to sql" do
      parameter = search_parameter.parameter
      parameter.search_model   = 'Patient'
      parameter.search_method  = 'age_at_case_collect'
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :chosen => true, :operator => nil, :parameter_value => FactoryGirl.create(:parameter_value, :name => 'first value', :search_value => 'first_value', :parameter => parameter) )
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :chosen => true, :operator => nil, :parameter_value => FactoryGirl.create(:parameter_value, :name => 'another value', :search_value => 'another_value', :parameter => parameter) )
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :chosen => false, :operator => nil, :parameter_value => FactoryGirl.create(:parameter_value, :name => 'yet another value', :search_value => 'yet_another_value', :parameter => parameter) )

      parameter.parameter_type = FactoryGirl.build(:parameter_type, :name => 'list')
      parameter.save!
      search_parameter.to_sql.should_not == {}
      search_parameter.to_sql[:predicates].should == "age_at_case_collect in (?)"
      search_parameter.to_sql[:values].should    ==  [['first_value', 'another_value']]
    end
  end

  describe 'using method-based parameters' do
    it "should throw error if 'to_sql' if method does not exist for selected model" do
      search_parameter.parameter.search_model   = 'Patient'
      search_parameter.parameter.search_method  = 'blah'
      lambda {search_parameter.to_sql}.should raise_error(RuntimeError, /does not respond to search method/)
    end

    it "should allow to convert search parameter to sql" do
      parameter = search_parameter.parameter
      parameter.search_model   = 'Patient'
      parameter.search_method  = 'having_gender'
      parameter.save!
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :value => '0', :operator => FactoryGirl.create(:operator, :symbol => '<', :text => 'is less than'))
      search_parameter.to_sql.should_not == {}
      search_parameter.to_sql[:predicates].should == "patients.gender in (?)"
      search_parameter.to_sql[:values].should     ==  [0.0]
    end
  end

  it "soft deletes search parameter values on soft delete" do
    FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :value => '0', :operator => FactoryGirl.create(:operator, :symbol => '<', :text => 'is less than'))
    search_parameter.deleted_at = Time.now
    search_parameter.save
    search_parameter.reload.search_parameter_values.should_not be_blank
    search_parameter.search_parameter_values.each do |spv|
      spv.should be_deleted
    end
  end

  describe "it detects if search parameter is disabled" do
    before(:each) do
      FactoryGirl.create(:search_parameter_value, :search_parameter => search_parameter, :value => '0', :operator => FactoryGirl.create(:operator, :symbol => '<', :text => 'is less than'))
    end

    it "disables search parameter without parameter" do
      search_parameter.should_not be_disabled
      search_parameter.parameter = nil
      search_parameter.should be_disabled
      search_parameter.warnings.full_messages.should include("Parameter has to be selected")
    end

    it "disables search parameter with deleted parameter" do
      search_parameter.should_not be_disabled
      search_parameter.parameter.deleted_at = Time.now
      search_parameter.should be_disabled
      search_parameter.warnings.full_messages.should include("Parameter has been deleted and has to be removed from the search")
    end

    it "disables search parameter without search parameter value" do
      search_parameter.should_not be_disabled
      search_parameter.search_parameter_values = []
      search_parameter.should be_disabled
      search_parameter.warnings.full_messages.should include("Parameter value has to be selected")
    end

    it "disables list search parameter without chosen search parameter value" do
      search_parameter.should_not be_disabled
      search_parameter.parameter.parameter_type = FactoryGirl.build(:parameter_type, :name => 'list')
      search_parameter.should be_disabled

      search_parameter.parameter.parameter_type = FactoryGirl.build(:parameter_type, :name => 'combobox')
      search_parameter.should_not be_disabled
    end

    it "disables search parameter with disabled search parameter value" do
      search_parameter.should_not be_disabled

      search_parameter.search_parameter_values.first.value = nil
      search_parameter.should be_disabled

      search_parameter.search_parameter_values.first.parameter_value = FactoryGirl.create(:parameter_value, :parameter => search_parameter.parameter)
      search_parameter.should_not be_disabled

      search_parameter.search_parameter_values.first.parameter_value.deleted_at = Time.now
      search_parameter.should be_disabled

      search_parameter.search_parameter_values.first.chosen = true
      search_parameter.should be_disabled
      search_parameter.warnings.should be_blank
    end
  end
end
