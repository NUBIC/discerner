require 'spec_helper'

class Person
  attr_accessor :gender
  
  def initialize(params={})
    @gender = params[:gender]
  end
  
  def self.all
    [Person.new(:gender => 'Male'), Person.new(:gender => 'Female')]
  end
  
  def self.ethnic_groups
    ['Hispanic or Latino', 'NOT Hispanic or Latino']
  end
end

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
  
  it "parses parameters with source model and method" do
    parser = Discerner::Parser.new()    
    dictionaries = %Q{
:dictionaries:
  - :name: Sample dictionary
    :parameter_categories:
      - :name: Demographic criteria
        :parameters:
          - :name: Ethnic group
            :searchable: true
            :parameter_type: list
            :search:
              :model: Patient
              :attribute: ethnic_grp
            :source:
              :model: Person
              :method: ethnic_groups
}
    parser.parse_dictionaries(dictionaries)
    Discerner::Dictionary.all.should_not be_empty
    Discerner::Dictionary.all.length.should == 1
    Discerner::Parameter.all.length.should == 1
    p = Discerner::Parameter.last
    p.name.should == 'Ethnic group'
    p.parameter_values.length.should == 2
    p.parameter_values.each do |pv|
      ['Hispanic or Latino', 'NOT Hispanic or Latino'].should include(pv.name)
    end
  end
  
    it "parses parameters with source attribute and method" do
      parser = Discerner::Parser.new()    
      dictionaries = %Q{
:dictionaries:
  - :name: Sample dictionary
    :parameter_categories:
      - :name: Demographic criteria
        :parameters:
          - :name: Gender
            :searchable: true
            :parameter_type: list
            :search:
              :model: Patient
              :attribute: gender
            :source:
              :model: Person
              :attribute: gender
}
      parser.parse_dictionaries(dictionaries)
      Discerner::Dictionary.all.should_not be_empty
      Discerner::Dictionary.all.length.should == 1
      Discerner::Parameter.all.length.should == 1
      p = Discerner::Parameter.last
      p.name.should == 'Gender'
      p.parameter_values.length.should == 2
      p.parameter_values.each do |pv|
        ['Male', 'Female'].should include(pv.name)
      end
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