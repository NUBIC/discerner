require 'spec_helper'

describe Discerner::SearchParameter do
  let!(:search_parameter) {
    s = Factory.build(:search)
    search_parameter = Factory.build(:search_parameter, :search => s)
    search_parameter.parameter.parameter_type = Factory(:parameter_type, :name => 'numeric')
    s.search_parameters << search_parameter
    s.dictionary = Discerner::Dictionary.last
    s.save!
    s.search_parameters.first
  }

  it "is valid with valid attributes" do
    search_parameter.should be_valid
  end

  it "allows to access matching search criteria values" do
    search_parameter.should respond_to :search_parameter_values
  end

  it "should accept attributes for search criteria values" do
    s = Discerner::SearchParameter.new( :search => Factory.build(:search),
      :search_parameter_values_attributes => { "0" => { :operator => Factory.build(:operator), :parameter_value => Factory.build(:parameter_value, :parameter => Discerner::Parameter.last)}})
    s.should be_valid
    s.save
    s.should have(1).search_parameter_values
  end

  it "should not throw error if 'to_sql' is called on parameter without search model" do
    lambda {search_parameter.to_sql}.should_not raise_error(RuntimeError, /could not be found/)
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
      Factory.create(:search_parameter_value, :search_parameter => search_parameter, :value => '50', :operator => Factory.create(:operator, :symbol => '<', :text => 'is less than'))
      Factory.create(:search_parameter_value, :search_parameter => search_parameter, :value => '60', :additional_value => '70', :operator => Factory.create(:operator, :symbol => 'between', :text => 'is in the range'))
      search_parameter.to_sql.should_not == {}
      search_parameter.to_sql[:predicates].should == "(age_at_case_collect < ? or age_at_case_collect between ? and ?)"
      search_parameter.to_sql[:values].should    ==  [50.0, 60.0, 70.0]
    end

    it "should allow to convert 'date' search parameter to sql" do
      parameter = search_parameter.parameter
      parameter.search_model   = 'Patient'
      parameter.search_method  = 'age_at_case_collect'
      parameter.parameter_type = Factory(:parameter_type, :name => 'date')
      parameter.save!
      date1 = '01/02/2009'
      date2 = '02/03/2009'
      date3 = '02/04/2009'
      Factory.create(:search_parameter_value, :search_parameter => search_parameter, :value => date1, :operator => Factory.create(:operator, :symbol => '<', :text => 'is less than'))
      Factory.create(:search_parameter_value, :search_parameter => search_parameter, :value => date2, :additional_value => date3, :operator => Factory.create(:operator, :symbol => 'between', :text => 'is in the range'))
      search_parameter.to_sql.should_not == {}
      search_parameter.to_sql[:predicates].should == "(age_at_case_collect < ? or age_at_case_collect between ? and ?)"
      search_parameter.to_sql[:values].should    ==  [date1.to_date, date2.to_date, date3.to_date]
    end

    it "should allow to convert 'text' and 'string' search parameter to sql" do
      parameter = search_parameter.parameter
      parameter.search_model   = 'Patient'
      parameter.search_method  = 'age_at_case_collect'

      Factory.create(:search_parameter_value, :search_parameter => search_parameter, :value => 'first string',  :operator => Factory.create(:operator, :symbol => 'is like', :text => 'is like'))
      Factory.create(:search_parameter_value, :search_parameter => search_parameter, :value => 'second string', :operator => Factory.create(:operator, :symbol => 'is not like', :text => 'is not like'))

      ['text', 'string'].each do |type|
        parameter.parameter_type = Discerner::ParameterType.find_by_name(type) || Factory(:parameter_type, :name => type)
        parameter.save!
        search_parameter.to_sql.should_not == {}
        search_parameter.to_sql[:predicates].should == "(age_at_case_collect is like ? or age_at_case_collect is not like ?)"
        search_parameter.to_sql[:values].should    ==  ['%first string%', '%second string%']
      end
    end

    it "should allow to convert 'combobox' search parameter to sql" do
      parameter = search_parameter.parameter
      parameter.search_model   = 'Patient'
      parameter.search_method  = 'age_at_case_collect'
      Factory.create(:search_parameter_value, :search_parameter => search_parameter, :operator => nil, :parameter_value => Factory.create(:parameter_value, :name => 'first value', :search_value => 'first_value', :parameter => parameter) )
      Factory.create(:search_parameter_value, :search_parameter => search_parameter, :operator => nil, :parameter_value => Factory.create(:parameter_value, :name => 'another value', :search_value => 'another_value', :parameter => parameter) )

      parameter.parameter_type = Factory(:parameter_type, :name => 'combobox')
      parameter.save!
      search_parameter.to_sql.should_not == {}
      search_parameter.to_sql[:predicates].should == "age_at_case_collect in (?)"
      search_parameter.to_sql[:values].should    ==  [['first_value', 'another_value']]
    end

    it "should allow to convert 'list' search parameter to sql" do
      parameter = search_parameter.parameter
      parameter.search_model   = 'Patient'
      parameter.search_method  = 'age_at_case_collect'
      Factory.create(:search_parameter_value, :search_parameter => search_parameter, :chosen => true, :operator => nil, :parameter_value => Factory.create(:parameter_value, :name => 'first value', :search_value => 'first_value', :parameter => parameter) )
      Factory.create(:search_parameter_value, :search_parameter => search_parameter, :chosen => true, :operator => nil, :parameter_value => Factory.create(:parameter_value, :name => 'another value', :search_value => 'another_value', :parameter => parameter) )
      Factory.create(:search_parameter_value, :search_parameter => search_parameter, :chosen => false, :operator => nil, :parameter_value => Factory.create(:parameter_value, :name => 'yet another value', :search_value => 'yet_another_value', :parameter => parameter) )

      parameter.parameter_type = Factory(:parameter_type, :name => 'list')
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
      Factory.create(:search_parameter_value, :search_parameter => search_parameter, :value => '0', :operator => Factory.create(:operator, :symbol => '<', :text => 'is less than'))
      search_parameter.to_sql.should_not == {}
      search_parameter.to_sql[:predicates].should == "patients.gender in (?)"
      search_parameter.to_sql[:values].should     ==  [0.0]
    end
  end

  it "soft deletes search parameter values on soft delete" do
    Factory.create(:search_parameter_value, :search_parameter => search_parameter, :value => '0', :operator => Factory.create(:operator, :symbol => '<', :text => 'is less than'))
    search_parameter.deleted_at = Time.now
    search_parameter.save
    search_parameter.reload.search_parameter_values.should_not be_blank
    search_parameter.search_parameter_values.each do |spv|
      spv.should be_deleted
    end
  end
end
