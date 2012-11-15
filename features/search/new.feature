Feature: Viewing existing searches
  A user should be able to create a new search

  @javascript
  Scenario: It should not allow to add search criteria until dictionary is selected
    Given search dictionaries are loaded
    When I go to the new search page 
    Then I should see "Search name"
    And I should see "Dictionary"
    And the element ".add_search_parameters" should not be visible
    And the element ".discerner_dictionary_required_message" should be visible
    
    When I select dictionary "Sample dictionary"
    Then the element ".add_search_parameters" should be visible
    And the element ".discerner_dictionary_required_message" should not be visible

  @javascript
  Scenario: It should allow to add search criteria if dictionary is selected
    Given search dictionaries are loaded
    When I go to the new search page 
    And I select dictionary "Sample dictionary"
    And I add search criteria
    Then I should see "Select"
    And I should see "Remove"
    
  @javascript
  Scenario: It should filter search criteria by selected dictionary
    Given search dictionaries are loaded
    When I go to the new search page 
    And I select dictionary "Sample dictionary"
    And I add search criteria
    And I open criteria dropdown
    
    Then the element ".div-criteria-popup .dictionary_sample_dictionary" should be visible
    And the element ".div-criteria-popup .dictionary_librarian_dictionary" should not be visible
    
    When I select dictionary "Librarian dictionary"
    And I add search criteria
    And I open criteria dropdown
    Then the element ".div-criteria-popup .dictionary_sample_dictionary" should not be visible
    And the element ".div-criteria-popup .dictionary_librarian_dictionary" should be visible

  @javascript
  Scenario: It should allow to select search criteria from the list
    Given search dictionaries are loaded
    When I go to the new search page 
    And I select dictionary "Sample dictionary"
    And I add "Age at case collection date" search criteria
    Then the element ".div-criteria-popup" should not be visible
    And the first search criteria should be "Age at case collection date"

  @javascript
  Scenario: It should filter operators by the type of the selected criteria
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page 
    And I select dictionary "Sample dictionary"
    And I add "Age at case collection date" search criteria

    Then ".operator select" in the first ".search_parameter" should have options "is equal to, is not equal to, is less than, is greater than, is in the range"
    And ".operator select" in the first ".search_parameter" should not have options "is like, is not like"

    When I select "Text search diagnosis" search criteria
    Then ".operator select" in the first ".search_parameter" should not have options "is equal to, is not equal to, is less than, is greater than, is in the range"
    And ".operator select" in the first ".search_parameter" should have options "is like, is not like"

  @javascript
  Scenario: It should display appropriate criteria selections
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page 
    And I select dictionary "Sample dictionary"
    And I add search criteria
    Then the element ".add_search_parameter_values" should not be visible
    
    When I select "Age at case collection date" search criteria
    Then the element ".search_parameter_value .value" should be visible 
    And the element ".search_parameter_value .additional_value" should not be visible 
    
    When I select "is in the range" from ".operator select" in the first ".search_parameter_value"
    Then the element ".search_parameter_value .value" should be visible 
    And the element ".search_parameter_value .additional_value" should be visible
    
  @javascript
  Scenario: It should display appropriate values for criteria selections
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page 
    And I select dictionary "Sample dictionary"
    And I add "Gender" search criteria
    Then the element ".search_parameter_value .value" should not be visible 
    And the element ".search_parameter_value .additional_value" should not be visible 
    And ".search_parameter_values" in the first ".search_parameter" should contain text "Female"
    And ".search_parameter_values" in the first ".search_parameter" should contain text "Indeterminent"
    And ".search_parameter_values" in the first ".search_parameter" should contain text "Male"
    And ".search_parameter_values" in the first ".search_parameter" should contain text "Unknown"

  @javascript
  Scenario: It should allow to add multiple search criteria
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page 
    And I select dictionary "Sample dictionary"
    And I add "Gender" search criteria
    And I add "Text search diagnosis" search criteria
    Then the element ".operator select" in the first ".search_parameter" should not be visible
    And ".search_parameter_values" in the first ".search_parameter" should contain text "Female"
    And ".operator select" in the last ".search_parameter" should have options "is like, is not like"
    And the element ".search_parameter_value .value" in the last ".search_parameter" should be visible 
    And the element ".search_parameter_value .additional_value" in the last ".search_parameter" should not be visible

  @javascript
  Scenario: It should allow to add and remove multiple criteria selections
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page 
    And I select dictionary "Sample dictionary"
    And I add "Date of birth" search criteria
    And I follow "Add selection" within the last ".search_parameter"
    Then ".operator select" in the first ".search_parameter_value" should have options "is equal to, is not equal to, is less than, is greater than, is in the range"
    And ".operator select" in the first ".search_parameter_value" should not have options "is like, is not like"
    Then ".operator select" in the last ".search_parameter_value" should have options "is equal to, is not equal to, is less than, is greater than, is in the range"
    And ".operator select" in the last ".search_parameter_value" should not have options "is like, is not like"
    
    When I select "is less than" from ".operator select" in the first ".search_parameter_value"
    And I select "is in the range" from ".operator select" in the last ".search_parameter_value"
    Then the element ".value" in the first ".search_parameter_value" should be visible 
    And the element ".additional_value" in the first ".search_parameter_value" should not be visible 
    And the element ".value" in the last ".search_parameter_value" should be visible 
    And the element ".additional_value" in the last ".search_parameter_value" should be visible
    
    When I follow "Remove" within the first ".search_parameter_value"
    And the element ".value" in the first ".search_parameter_value" should be visible 
    And the element ".additional_value" in the first ".search_parameter_value" should be visible
    
  @javascript
  Scenario: It should not allow to add multiple criteria selections for criteria fith fixed number of options
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page 
    And I select dictionary "Sample dictionary"
    And I add "Gender" search criteria
    Then the element ".add_search_parameter_values" in the last ".search_parameter" should not be visible 
    
  @javascript
  Scenario: It should remove criteria selections on dictionary change
   Given search dictionaries are loaded
   And search operators are loaded
   When I go to the new search page 
   And I select dictionary "Sample dictionary"
   And I add "Gender" search criteria
   And I add "Text search diagnosis" search criteria
   And I select dictionary "Librarian dictionary"
   Then the element ".search_parameter" should not be visible
   Then the element ".add_search_parameters" should be visible
  
  @javascript
  Scenario: It should display datepickers for datetime fields
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page 
    And I select dictionary "Sample dictionary"
    And I add "Age at case collection date" search criteria
    And I select "is in the range" from ".operator select" in the first ".search_parameter_value"
    
    When I focus on ".value input" within the last ".search_parameter"
    Then the element ".ui-datepicker-calendar" should not be visible
    When I focus on ".additional_value input" within the last ".search_parameter"
    Then the element ".ui-datepicker-calendar" should not be visible
    
    When I add "Date of birth" search criteria
    When I focus on ".value input" within the last ".search_parameter"
    Then the element ".ui-datepicker-calendar" should be visible
  
    When I select "Oct" from ".ui-datepicker-month" in the first ".ui-datepicker"
    And I select "2012" from ".ui-datepicker-year" in the first ".ui-datepicker"
    And I follow "22"
    Then the last search criteria selection value should be "2012-10-22"

  @javascript
  Scenario: It should not allow to save search without criteria
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page
    And I fill in "Search name" with "Awesome search"
    And I press "Search"
    Then I should be on the searches page
    And I should see "Search should have at least one search criteria."
    
    When I select dictionary "Sample dictionary"
    And I press "Search"
    Then I should be on the searches page
    And I should see "Search should have at least one search criteria."
    
    When I select dictionary "Sample dictionary"
    And I add search criteria
    And I press "Search"
    Then I should be on the searches page
    And I should see "Search should have at least one search criteria."

  @javascript
  Scenario: It should save created search and redirect to edit page
    Given I create search with name "Awesome search"
    Then I should be on the search edit page
    And I should see "Awesome search"
    And I should see "Sample dictionary"
    And the element ".add_search_parameters" should be visible
    And the element ".discerner_dictionary_required_message" should not be visible
    