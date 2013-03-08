require 'spec_helper'

describe Discerner::SearchParameterValue do
  let(:search_parameter_value) { 
    s = Factory.build(:search)
    search_parameter = Factory.build(:search_parameter, :search => s)
    p = search_parameter.parameter
    p.search_method = 'age'
    p.search_model = 'Person'
    p.save!
    s.search_parameters << search_parameter
    s.dictionary = Discerner::Dictionary.last
    s.save!
    Factory.build(:search_parameter_value, :search_parameter => s.search_parameters.first)
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
  
  it "allows to generate sql for search values with 'is less than', 'is not equal to', 'is greater than', 'is equal to' operators" do
    search_parameter_value.value = '50'
    
    [['is less than','<'], ['is not equal to', '!='], ['is greater than','>'], ['is equal to', '=']].each do |o|
      search_parameter_value.operator = Discerner::Operator.find_by_symbol(o.last) || Factory.create(:operator, :symbol => o.last, :text => o.first)
      search_parameter_value.to_sql.should_not == {}
      search_parameter_value.to_sql[:predicates].should == "age #{o.last} ?"
      search_parameter_value.to_sql[:values].should == '50'
    end
  end
  
  it "allows to generate sql for search values with 'is in the range' operator" do
    search_parameter_value.value = '40'
    search_parameter_value.additional_value = '50'
    
    search_parameter_value.operator = Discerner::Operator.find_by_symbol('between') || Factory.create(:operator, :symbol => 'between', :text => 'is in the range')
    search_parameter_value.to_sql.should_not == {}
    search_parameter_value.to_sql[:predicates].should == "age between ? and ?"
    search_parameter_value.to_sql[:values].should == ["40", "50"]
  end
  
  it "allows to generate sql for search values with 'is like', 'is not like' operators" do
    search_parameter_value.value = '50'
    
    [['is like','is like'], ['is not like', 'is not like']].each do |o|
      search_parameter_value.operator = Discerner::Operator.find_by_symbol(o.last) || Factory.create(:operator, :symbol => o.last, :text => o.first)
      search_parameter_value.to_sql.should_not == {}
      search_parameter_value.to_sql[:predicates].should == "age #{o.last} ?"
      search_parameter_value.to_sql[:values].should == '%50%'
    end
  end
  it "self-destroyes if belongs to list or combobox parameter and references deleted value and not chosen" do
    search_parameter_value.parameter_value = Factory.create(:parameter_value, :parameter => search_parameter_value.search_parameter.parameter)
    search_parameter_value.parameter_value.deleted_at = Time.now
    search_parameter_value.chosen = false
    search_parameter_value.save
    search_parameter_value.class.should exist(search_parameter_value)

    search_parameter_value.search_parameter.parameter.parameter_type.name = 'list'
    search_parameter_value.save
    search_parameter_value.class.should_not exist(search_parameter_value)
  end
end
