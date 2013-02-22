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

Given /^(?:(exportable) )?search "([^\"]*)" exists$/ do |exportable, name|
  s = Factory.build(:search, :name => name)
  p = Discerner::Parameter.last || Factory.build(:parameter)
  s.search_parameters << Factory.build(:search_parameter, :search => s, :parameter => p)
  unless exportable.blank?
    p.export_model = 'Person'
    p.export_method = 'some_method'
    p.save
  end
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

Given /^I create search(?: for dictionary "([^\"]*)")?(?: with name "([^\"]*)")?$/ do |dictionary, name|
  dictionary ||= "Sample dictionary"
  steps %Q{
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page
    And I select dictionary "#{dictionary}"
    And I fill in "Search name" with "#{name}"
  }
  if dictionary == "Sample dictionary"
    set_sample_dictionary_search_parameters
  else 
    set_librarian_dictionary_search_parameters
  end
end

Given /^I create combined search(?: for dictionary "([^\"]*)")?(?: with name "([^\"]*)")?$/ do |dictionary, name|
  dictionary ||= "Sample dictionary"
  steps %Q{
    Given I create search for dictionary "#{dictionary}" with name "Awesome search" 
    When I go to the new search page 
    And I select dictionary "#{dictionary}"
    And I add combined search
    And I fill in "input.autocompleter-dropdown" autocompleter within the first ".search_combination" with "Awesome search"
  }
  if dictionary == "Sample dictionary"
    set_sample_dictionary_search_parameters
  else 
    set_librarian_dictionary_search_parameters
  end
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

Then /^I should receive a CSV file(?: "([^\"]*)")?/ do |file|
  result = page.response_headers['Content-Type'].should include("text/csv")
  if result
    result = page.response_headers['Content-Disposition'].should include(file)
  end
  result
end

When /^I add combined search$/ do
  steps %Q{
    When I follow "Add search"
  }
end

When /^I open combined search dropdown$/ do
  steps %Q{
    When I press "Show All Items" within the last ".combined_search"
  }
end

def set_sample_dictionary_search_parameters
  steps %Q{
    And I add "Gender" search criteria
    And I wait 1 seconds
    And I check "input[type='checkbox']" within the first ".search_parameter .chosen"
    And I add "Date of birth" search criteria
    And I enter value "2012-10-22" within the last search criteria
    And I press "Search"
  }
end

def set_librarian_dictionary_search_parameters
  steps %Q{
    And I add "Title" search criteria
    And I enter value "Best book ever" within the last search criteria
    And I add "Keyword" search criteria
    And I enter value "random word" within the last search criteria
    And I press "Search"
  }
end
  