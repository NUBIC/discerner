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
  s = FactoryGirl.build(:search, name: name)
  p = Discerner::Parameter.last || FactoryGirl.build(:parameter)
  p.search_method = 'age'
  p.search_model = 'Person'
  unless exportable.blank?
    p.export_model = 'Person'
    p.export_method = 'some_method'
  end
  p.save!
  search_parameter = FactoryGirl.build(:search_parameter, search: s, parameter: p)
  s.search_parameters << search_parameter
  s.dictionary = Discerner::Dictionary.last
  s.last_executed = Time.now + (Discerner::Search.count).minutes
  s.save!
  o = Discerner::Operator.last || FactoryGirl.create(:operator)
  FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first, operator: o)
end

Given /^search "([^\"]*)" is disabled$/ do |name|
  search = Discerner::Search.where(name: name).first
  p = search.search_parameters.first.parameter
  p.deleted_at = Time.now
  p.save
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
    And I fill in "input.search_combinations_combobox_autocompleter" autocompleter within the first ".search_combination" with "Awesome search"
  }
  if dictionary == "Sample dictionary"
    set_sample_dictionary_search_parameters
  else
    set_librarian_dictionary_search_parameters
  end
end

When /^I enter value "([^\"]*)" within the (first|last) search criteria$/ do |value, position|
  steps %Q{
    When I enter "#{value}" into ".value input[type='text']" within the #{position} ".search_parameter .search_parameter_value"
  }
end

When /^I enter additional value "([^\"]*)" within the (first|last) search criteria$/ do |value, position|
  steps %Q{
    When I enter "#{value}" into ".additional_value input[type='text']" within the #{position} ".search_parameter .search_parameter_value"
  }
end

Then /^the (first|last) search criteria should(?: (not))? be "([^\"]*)"$/ do |position, negation, value|
  if negation.blank?
    steps %Q{
      Then ".parameter select" in the #{position} ".search_parameter" should have "#{value}" selected
    }
  else
    steps %Q{
      Then ".parameter select" in the #{position} ".search_parameter" should not have "#{value}" selected
    }
  end
end

Then /^the (first|last) search criteria selection value should be "([^\"]*)"$/ do |position, value|
  steps %Q{
    Then ".value input[type='text']" in the #{position} ".search_parameter_value" should contain "#{value}"
  }
end

Then /^the (first|last) search criteria selection additional value should be "([^\"]*)"$/ do |position, value|
  steps %Q{
    Then ".additional_value input[type='text']" in the #{position} ".search_parameter_value" should contain "#{value}"
  }
end

Then /^the search should have (\d+) criteria$/ do |count|
  all("tr.search_parameter", visible: true).count.should == count.to_i
end

Given /^only "([^\"]*)" dictionary exists$/ do |name|
  dictionaries = Discerner::Dictionary.where("name not like ?", name)
  dictionaries.each{|d| d.parameter_categories.destroy_all}
  dictionaries.destroy_all
end

Then /^I should receive a "([^\"]*)" file(?: with name "([^\"]*)")?/ do |extension, filename|
  download_extension.should == extension
  download_filename.should match(filename) unless filename.blank?
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

Given /^value "([^\"]*)" for parameter "([^\"]*)" is marked as deleted$/ do |value_name, parameter_name|
  p = Discerner::Parameter.where(name: parameter_name).first
  v = p.parameter_values.where(name: value_name).first
  v.deleted_at = Time.now
  v.save
end

Given /^parameter "([^\"]*)" is marked as deleted$/ do |name|
  r = Discerner::Parameter.where(name: name).first
  r.deleted_at = Time.now
  r.save
end

Given /^parameter category "([^\"]*)" is marked as deleted$/ do |name|
  r = Discerner::ParameterCategory.where(name: name).first
  r.deleted_at = Time.now
  r.save
end

Given /^parameters in category "([^\"]*)" are marked as deleted$/ do |name|
  r = Discerner::ParameterCategory.where(name: name).first
  r.parameters.each do |p|
    p.deleted_at = Time.now
    p.save
  end
end

Given /^dictionary "([^\"]*)" is marked as deleted$/ do |name|
  r = Discerner::Dictionary.where(name: name).first
  r.deleted_at = Time.now
  r.save
end

Given /^search with name "([^\"]*)" is marked as deleted$/ do |name|
  r = Discerner::Search.where(name: name).first
  r.deleted_at = Time.now
  r.save
end

Given /^search with name "([^\"]*)" has exportable parameters "([^\"]*)"$/ do |name, parameter_names|
  search = Discerner::Search.where(name: name).first
  parameter_names.split(', ').each do |name|
    p = Discerner::Parameter.where(name: name).first
    search.export_parameters.create(parameter_id: p.id)
  end
end

Given /^search "([^\"]*)" combines in search "([^\"]*)"$/ do |search_name, anoher_search_name|
  steps %Q{
    Given I create search with name "#{anoher_search_name}"
    And I create search with name "#{search_name}"
    When I go to the search "#{search_name}" edit page
    And I add combined search
    And I fill in "input.search_combinations_combobox_autocompleter" autocompleter within the first ".search_combination" with "#{anoher_search_name}"
    And I add "Text search diagnosis" search criteria
    And I enter value "adenocarcinoma" within the last search criteria
    And I press "Search"
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

When /^I wait for the ajax request to finish$/ do
  start_time = Time.now
  page.evaluate_script('jQuery.isReady&&jQuery.active==0').class.should_not eql(String) until page.evaluate_script('jQuery.isReady&&jQuery.active==0') or (start_time + 5.seconds) < Time.now do
    sleep 1
  end
end
