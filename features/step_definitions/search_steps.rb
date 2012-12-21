Given /^search dictionaries are loaded$/ do
  file = 'test/dummy/lib/setup/dictionaries.yml'
  parser = Discerner::Parser.new()
  parser.parse_dictionaries(File.read(file))
end

Given /^search operators are loaded$/ do
  file = 'lib/setup/operators.yml'
  parser = Discerner::Parser.new()
  parser.parse_operators(File.read(file))
end

Given /^search "([^\"]*)" exists$/ do |name|
  s = Factory.build(:search, :name => name)
  s.dictionary = Factory.build(:dictionary)
  s.search_parameters << Factory.build(:search_parameter, :search => s, :parameter => Discerner::Parameter.first)
  s.save!
end

When /^I select dictionary "([^\"]*)"$/ do |dictionary|
  steps %Q{
    When I select "#{dictionary}" from "Dictionary"
  }
end

When /^I add search criteria$/ do
  steps %Q{
    When I follow "Add criteria"
  }
end

When /^I select "([^\"]*)" search criteria$/ do |value|
  steps %Q{
    When I open criteria dropdown
    And I follow "#{value}" within the last ".search_parameter"
  }
end

When /^I open criteria dropdown$/ do
  steps %Q{
    When I follow "Select" within the last ".search_parameter"
  }
end

When /^I add "([^\"]*)" search criteria$/ do |value|
  steps %Q{
    When I follow "Add criteria"
    And I select "#{value}" search criteria
  }
end

Given /^I create search(?: with name "([^\"]*)")?$/ do |name|
  steps %Q{
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I fill in "Search name" with "#{name}"
    And I add "Gender" search criteria
    And I wait 1 seconds
    And I check "input[type='checkbox']" within the first ".search_parameter .chosen"
    And I add "Date of birth" search criteria
    And I focus on ".value input" within the last ".search_parameter"
    And I select "Oct" from ".ui-datepicker-month" in the first ".ui-datepicker"
    And I select "2012" from ".ui-datepicker-year" in the first ".ui-datepicker"
    And I follow "22"
    And I press "Search"
  }
end

When /^I enter value "([^\"]*)" within the (first|last) search criteria$/ do |value, position| 
  steps %Q{
    When I enter "#{value}" into ".value input[type='text']" within the #{position} ".search_parameter"
  }
end

When /^I enter additional value "([^\"]*)" within the (first|last) search criteria$/ do |value, position| 
  steps %Q{
    When I enter "#{value}" into ".additional_value input[type='text']" within the #{position} ".search_parameter"
  }
end

Then /^the (first|last) search criteria should(?: (not))? be "([^\"]*)"$/ do |position, negation, value|
  if negation.blank?
    steps %Q{
      Then ".parameters_combobox_autocompleter" in the #{position} ".search_parameter" should have "#{value}" selected
    }
  else
    steps %Q{
      Then ".parameters_combobox_autocompleter" in the #{position} ".search_parameter" should not have "#{value}" selected
    }
  end
end

Then /^the (first|last) search criteria selection value should be "([^\"]*)"$/ do |position, value|
  steps %Q{
    Then ".value" in the #{position} ".search_parameter_value" should contain "#{value}"
  }
end

Then /^the (first|last) search criteria selection additional value should be "([^\"]*)"$/ do |position, value|
  steps %Q{
    Then ".value" in the #{position} ".search_parameter_value" should contain "#{value}"
  }
end

Then /^the search should have (\d+) criteria$/ do |count|
  all("tr.search_parameter", :visible => true).count.should == count.to_i
end

Given /^ony "([^\"]*)" dictionary exists$/ do |name|
  dictionaries = Discerner::Dictionary.where("name not like ?", name)
  dictionaries.each{|d| d.parameter_categories.destroy_all}
  dictionaries.destroy_all
end