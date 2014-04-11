require 'spec_helper'

describe Discerner::SearchParameterValue do
  let(:search_parameter_value) {
    s = FactoryGirl.build(:search)
    search_parameter = FactoryGirl.build(:search_parameter, :search => s)
    p = search_parameter.parameter
    p.search_method = 'age'
    p.search_model = 'Person'
    p.save!
    s.search_parameters << search_parameter
    s.dictionary = Discerner::Dictionary.last
    s.save!
    FactoryGirl.create(:search_parameter_value, :search_parameter => s.search_parameters.first)
  }

  it "is valid with valid attributes" do
    search_parameter_value.should be_valid
  end

  it "allows to access matching search criteria" do
    search_parameter_value.should respond_to :search_parameter
  end

  it "should throw error if 'to_sql' method is called and operator is not defined" do
    search_parameter_value.operator = nil
    lambda {search_parameter_value.to_sql}.should raise_error(RuntimeError, /Search operator has to be defined/)
  end

  it "allows to generate sql for search values with 'comparison' operators" do
    search_parameter_value.value = '50'
    search_parameter_value.operator = Discerner::Operator.find_by_symbol('>') || FactoryGirl.create(:operator, :symbol => '>', :text => 'is greater', :operator_type => 'comparison')
    search_parameter_value.to_sql.should_not == {}
    search_parameter_value.to_sql[:predicates].should == "age > ?"
    search_parameter_value.to_sql[:values].should == '50'
  end

  it "allows to generate sql for search values with 'range' operator" do
    search_parameter_value.value = '40'
    search_parameter_value.additional_value = '50'
    search_parameter_value.operator = Discerner::Operator.find_by_symbol('between') || FactoryGirl.create(:operator, :symbol => 'between', :text => 'is in the range', :operator_type => 'range')
    search_parameter_value.to_sql.should_not == {}
    search_parameter_value.to_sql[:predicates].should == "age between ? and ?"
    search_parameter_value.to_sql[:values].should == ["40", "50"]
  end

  it "allows to generate sql for search values with 'text_comparison' operators" do
    search_parameter_value.value = '50'
    search_parameter_value.operator = Discerner::Operator.find_by_symbol('is not like') || FactoryGirl.create(:operator, :symbol => 'is not like', :text => 'is not like', :operator_type => 'text_comparison')
    search_parameter_value.to_sql.should_not == {}
    search_parameter_value.to_sql[:predicates].should == "age is not like ?"
    search_parameter_value.to_sql[:values].should == '%50%'
  end

  it "allows to generate sql for search values with 'presence' operators" do
    search_parameter_value.value = '50'
    search_parameter_value.operator = Discerner::Operator.find_by_symbol('none') || FactoryGirl.create(:operator, :symbol => 'is not null', :text => 'none', :operator_type => 'presence')
    search_parameter_value.to_sql.should_not == {}
    search_parameter_value.to_sql[:predicates].should == "age is not null"
    search_parameter_value.to_sql[:values].should == nil
    search_parameter_value.should_not be_disabled
    search_parameter_value.warnings.full_messages.should be_blank
  end

  it "detects if value is blank" do
    search_parameter_value.should_not be_disabled
    search_parameter_value.warnings.full_messages.should be_blank
    search_parameter_value.value = nil
    search_parameter_value.should be_disabled
    search_parameter_value.warnings.full_messages.should include('Parameter value has to be selected')
  end

  it "detects if chosen value is deleted" do
    search_parameter_value.search_parameter.parameter.parameter_type.name = 'list'
    search_parameter_value.parameter_value = FactoryGirl.create(:parameter_value, :parameter => search_parameter_value.search_parameter.parameter)

    search_parameter_value.parameter_value.deleted_at = Time.now
    search_parameter_value.should be_disabled
    search_parameter_value.warnings.full_messages.should_not be_blank

    search_parameter_value.chosen = true
    search_parameter_value.should be_disabled
    search_parameter_value.warnings.full_messages.should include('Parameter value has been deleted and has to be removed from the search')

    search_parameter_value.search_parameter.parameter.parameter_type.name = 'combobox'
    search_parameter_value.should be_disabled
    search_parameter_value.warnings.full_messages.should include('Parameter value has been deleted and has to be removed from the search')
  end

  it "detects if search parameter value is in a wrong format" do
    search_parameter_value.search_parameter.parameter.parameter_type.name = 'date'
    search_parameter_value.value = '99-99-009'
    search_parameter_value.should be_disabled
    search_parameter_value.warnings.full_messages.should include('Provided date is not valid')

    search_parameter_value.additional_value = '99-99-009'
    search_parameter_value.should be_disabled
    search_parameter_value.warnings.full_messages.should include('Provided date is not valid')

    search_parameter_value.value = '01-02-2003'
    search_parameter_value.should be_disabled
    search_parameter_value.warnings.full_messages.should include('Provided date is not valid')

    search_parameter_value.additional_value = '01-02-2003'
    search_parameter_value.should_not be_disabled
    search_parameter_value.warnings.full_messages.should be_blank

    #search_parameter_value.value = '01---02-2003'
    #search_parameter_value.should be_disabled
    #search_parameter_value.warnings.full_messages.should include('Provided date is not valid')

    search_parameter_value.value = 'xx'
    search_parameter_value.should be_disabled
    search_parameter_value.warnings.full_messages.should include('Provided date is not valid')

    search_parameter_value.value = '09-09-0912'
    search_parameter_value.should be_disabled
    search_parameter_value.warnings.full_messages.should include('Provided date is not valid')
  end

  it "detects if combobox parameter value is not selected" do
    search_parameter_value.should_not be_disabled
    search_parameter_value.search_parameter.parameter.parameter_type.name = 'combobox'
    search_parameter_value.operator = nil
    search_parameter_value.parameter_value_id = nil
    search_parameter_value.should be_disabled
  end

  it "self-destroyes if belongs to list or combobox parameter and references deleted value and not chosen" do
    search_parameter_value.parameter_value = FactoryGirl.create(:parameter_value, :parameter => search_parameter_value.search_parameter.parameter)
    search_parameter_value.parameter_value.deleted_at = Time.now
    search_parameter_value.chosen = false
    search_parameter_value.save
    search_parameter_value.class.should exist(search_parameter_value)

    search_parameter_value.search_parameter.parameter.parameter_type.name = 'list'
    search_parameter_value.save
    search_parameter_value.class.should_not exist(search_parameter_value)
  end

end
