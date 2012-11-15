require 'spec_helper'

describe Discerner::Parser do
  it "parses operators" do
    file = 'lib/setup/operators.yml'
    parser = Discerner::Parser.new()
    parser.parse_operators(File.read(file))
    
    Discerner::Operator.all.should_not be_empty
    Discerner::Operator.where(:text => 'is not like').should_not be_empty
    Discerner::ParameterType.all.should_not be_empty
  end
  
  it "parses dictionaries" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new(:trace => true)
    parser.parse_dictionaries(File.read(file))
    
    Discerner::Dictionary.all.should_not be_empty
    Discerner::Dictionary.all.length.should == 3
    
    dictionary = Discerner::Dictionary.find_by_name('Sample dictionary')
    dictionary.should_not be_blank
    dictionary.should have(2).parameter_categories
    dictionary.should_not be_deleted
    
    dictionary.parameter_categories.first.should have(6).parameters
    dictionary.parameter_categories.first.should_not be_deleted
    
    dictionary.parameter_categories.last.should have(2).parameters
    dictionary.parameter_categories.last.should_not be_deleted
    
    Discerner::Parameter.all.count.should == 15
    
    dictionary = Discerner::Dictionary.find_by_name('Deleted dictionary')
    dictionary.should be_deleted
    dictionary.should have(1).parameter_categories
    dictionary.parameter_categories.first.should be_deleted
    
    dictionary.parameter_categories.first.should have(1).parameters
    dictionary.parameter_categories.first.parameters.first.should be_deleted    
    
    Discerner::ParameterValue.all.length.should == 22
  end
    
  it "restores soft deleted dictionaries if they are not marked as deleted in the dictionary definition" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new()
    parser.parse_dictionaries(File.read(file))
    
    Discerner::Dictionary.all.each do |d|
      d.deleted_at = Time.now
      d.save
    end
    
    parser.parse_dictionaries(File.read(file))
    Discerner::Dictionary.find_by_name('Sample dictionary').should_not be_blank
    Discerner::Dictionary.find_by_name('Sample dictionary').should_not be_deleted
    Discerner::Dictionary.find_by_name('Deleted dictionary').should_not be_blank
    Discerner::Dictionary.find_by_name('Deleted dictionary').should be_deleted
  end
  
  it "restores soft deleted parameter categories if they are not marked as deleted in the dictionary definition" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new()
    parser.parse_dictionaries(File.read(file))
    
    Discerner::ParameterCategory.all.each do |d|
      d.deleted_at = Time.now
      d.save
    end
    
    parser.parse_dictionaries(File.read(file))
    Discerner::ParameterCategory.all.each do |d|
      if d.name == 'Deleted category A'
        d.should be_deleted 
      else
        d.should_not be_deleted
      end
    end
  end
  
  it "restores soft deleted parameters if they are not marked as deleted in the dictionary definition" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new()
    parser.parse_dictionaries(File.read(file))
    
    Discerner::Parameter.all.each do |d|
      d.deleted_at = Time.now
      d.save
    end
    
    parser.parse_dictionaries(File.read(file))
    Discerner::Parameter.all.each do |d|
      if d.name == 'Deleted date parameter'
        d.should be_deleted 
      else
        d.should_not be_deleted
      end
    end
  end
end