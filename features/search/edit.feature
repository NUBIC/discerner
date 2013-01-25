Feature: Viewing existing searches
  A user should be able to edit a search

  @javascript
  Scenario: It should load saved search
    Given I create search with name "Awesome search"
    When I am on the search edit page
    Then the first search criteria should be "Gender"
    And the last search criteria should be "Date of birth"
    And the last search criteria selection value should be "2012-10-22"
    And I should see "Awesome search"
    And I should see "Sample dictionary"
    And the element ".add_search_parameters" should be visible
    And the element ".discerner_dictionary_required_message" should not be visible
    
  @javascript
  Scenario: It should render results template
    Given I create search with name "Awesome search"
    When I am on the search edit page
    Then I should see "Results for search on the `Sample dictionary` dictionary can be added here"
  
  @javascript
  Scenario: It should allow to rename the saved search
    Given I create search with name "Awesome search" 
    When I am on the search edit page
    Then I should see "Edit"
    
    When I follow "Edit"
    And I fill in "search_name" with "Not that great after all"
    And I follow "Cancel"
    Then I should see "Search name: Awesome search"
    And I should not see "Cancel"
    And I should not see "search_name"
    
    When I follow "Edit"
    And I fill in "search_name" with ""
    And I press "Submit"
    Then I should not see "Search name: Awesome search"
    And I should not see "Cancel"
    And I should not see "search_name"
    
    When I follow "Edit"
    And I fill in "search_name" with "Not so awesome search"
    And I press "Submit"
    Then I should see "Search name: Not so awesome search"
    And I should not see "Cancel"
    And I should not see "search_name"

  @javascript
  Scenario: It should allow to add and remove search criteria
    Given I create search with name "Awesome search" 
    When I am on the search edit page
    And I add "Text search diagnosis" search criteria
    And I enter value "adenocarcinoma" within the last search criteria
    And I press "Search"
    Then I should see "Search was successfully updated"
    And the last search criteria should be "Text search diagnosis"
    And the last search criteria selection value should be "adenocarcinoma"
    
    When I follow "Remove" within the last ".search_parameter"
    And I press "Search"
    Then I should see "Search was successfully updated"
    And the first search criteria should be "Date of birth"
    And the first search criteria selection value should be "2012-10-22"
    
  @javascript
  Scenario: It should allow to add and remove multiple criteria selections
    Given I create search with name "Awesome search" 
    
    When I follow "Add selection" within the last ".search_parameter"
    And I select "is in the range" from ".operator select" in the last ".search_parameter_value"
    And I enter value "2012-11-01" within the last search criteria
    And I enter additional value "2012-11-22" within the last search criteria
    And I press "Search"
    And the last search criteria selection value should be "2012-11-01"
    And the last search criteria selection additional value should be "2012-11-22"
    And ".operator select" in the last ".search_parameter_value" should have "is in the range" selected

    When I follow "Remove" within the last ".search_parameter_value"
    And I press "Search"
    And the last search criteria selection value should be "2012-10-22"
    And the element ".additional_value" in the last ".search_parameter_value" should not be visible 
    And ".operator select" in the last ".search_parameter_value" should have "is equal to" selected

@javascript
  Scenario: In should allow to export search results
    Given I create search with name "Awesome search" 
    When I am on the search edit page
    Then I should see "Export"
    
    When I follow "Export"
    Then I should see "Case criteria"
    And the "Date of birth" checkbox should be checked
    And the "Gender" checkbox should be checked