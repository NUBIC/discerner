Feature: Viewing existing searches
  A user should be able to create a new search

  @javascript
  Scenario: It should not allow to add search criteria until dictionary is selected
    Given search dictionaries are loaded
    When I go to the new search page
    Then "div.discerner_search_name" should contain text "Search name"
    And "div.discerner_search_dictionary" should contain text "Dictionary"
    And the element ".add_search_parameters" should not be visible
    And the element ".discerner_dictionary_required_message" should be visible

    When I select dictionary "Sample dictionary"
    And I wait 5 seconds
    Then the element ".add_search_parameters" should be visible
    And the element ".discerner_dictionary_required_message" should not be visible
    And ".discerner-buttons" should not contain text "Export options"

  Scenario: It should not render results template for a new search
    Given search dictionaries are loaded
    When I go to the new search page
    Then ".discerner" should not contain text "Results for search on the `Sample dictionary` dictionary can be added here"

  @javascript
  Scenario: It should allow to add search criteria if dictionary is selected
    Given search dictionaries are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    Then ".parameter" in the first ".search_parameter" should contain text "Select"
    And ".remove" in the first ".search_parameter" should contain text "Remove"
    And ".parameter_boolean_operator" in the first ".search_parameter" should contain text "where"

  @javascript
  Scenario: It should display only serchable parameters
    Given search dictionaries are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I open criteria dropdown
    Then ".parameter select" in the first ".search_parameter" should have options "Demographic criteria - Age at case collection date, Demographic criteria - Ethnic group, Demographic criteria - Gender, Demographic criteria - Race, Case criteria - Text search diagnosis"
    And ".parameter select" in the first ".search_parameter" should not have options "Demographic criteria - Age based on current date"

  @javascript
  Scenario: It should filter search criteria by selected dictionary
    Given search dictionaries are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I open criteria dropdown

    Then the element ".div-category-popup .dictionary_sample_dictionary" should be visible
    And the element ".div-category-popup .dictionary_librarian_dictionary" should not be visible

    When I select dictionary "Librarian dictionary"
    # And I add search criteria
    And I open criteria dropdown
    Then the element ".div-category-popup .dictionary_sample_dictionary" should not be visible
    And the element ".div-category-popup .dictionary_librarian_dictionary" should be visible

  @javascript
  Scenario: It should allow to select search criteria from the list
    Given search dictionaries are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I select "Age at case collection date" search criteria
    Then the element ".div-category-popup" should not be visible
    And ".parameter input.ui-autocomplete-input" in the first ".search_parameter" should contain "Demographic criteria - Age at case collection date"

  @javascript
  Scenario: It should correctly select critetia that have the same name
    Given search dictionaries are loaded
    When I go to the new search page
    And I select dictionary "Librarian dictionary"
    And I open criteria dropdown
    And I follow "Type" within the last ".parameter_category"
    And ".parameter input.ui-autocomplete-input" in the first ".search_parameter" should contain "Book criteria - Type"

  @javascript
  Scenario: It should filter operators by the type of the selected criteria
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I add "Age at case collection date" search criteria

    Then ".operator select" in the last ".search_parameter_value" should have options "is equal to, is not equal to, is less than, is greater than, is in the range"
    And ".operator select" in the last ".search_parameter_value" should not have options "is like, is not like"

    When I select "Text search diagnosis" search criteria
    Then ".operator select" in the last ".search_parameter_value" should not have options "is equal to, is not equal to, is less than, is greater than, is in the range"
    And ".operator select" in the last ".search_parameter_value" should have options "is like, is not like"

  @javascript
  Scenario: It should display appropriate criteria selections
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
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
    And I select "Gender" search criteria
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
    And I select "Gender" search criteria
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
    And I select "Date of birth" search criteria
    And I follow "Add selection" within the last ".search_parameter"
    Then ".operator select" in the first ".search_parameter_value" should have options "is equal to, is not equal to, is less than, is greater than, is in the range, none, not none"
    And ".operator select" in the first ".search_parameter_value" should not have options "is like, is not like"
    Then ".operator select" in the last ".search_parameter_value" should have options "is equal to, is not equal to, is less than, is greater than, is in the range, is in the range, none, not none"
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

    When I follow "Add selection" within the last ".search_parameter"
    And I select "none" from ".operator select" in the last ".search_parameter_value"
    Then the element ".value" in the last ".search_parameter_value" should not be visible
    And the element ".additional_value" in the last ".search_parameter_value" should not be visible

  @javascript
  Scenario: It should not allow to add multiple criteria selections for criteria fith fixed number of options
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I select "Gender" search criteria
    Then the element ".add_search_parameter_values" in the last ".search_parameter" should not be visible

  @javascript
  Scenario: It should remove criteria selections on dictionary change
   Given search dictionaries are loaded
   And search operators are loaded
   When I go to the new search page
   And I select dictionary "Sample dictionary"
   And I select "Gender" search criteria
   And I add "Text search diagnosis" search criteria
   And I select dictionary "Librarian dictionary"
   Then the element ".search_parameter" should be visible
   And ".search_parameter select" in the first ".search_parameter" should not have "Gender" selected
   And the element ".add_search_parameters" should be visible

  @javascript
  Scenario: It should display datepickers for datetime fields
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I select "Age at case collection date" search criteria
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
  Scenario: It should validate date format
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I select "Date of birth" search criteria
    And I enter value "2012-10--" within the last search criteria
    And I press "Search"
    Then "td.warnings" in the first ".search_parameter_values .error" should contain text "Provided date is not valid"

  @javascript
  Scenario: It should not allow to save search without criteria
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page
    And I fill in "Search name" with "Awesome search"
    And I press "Search"
    Then I should be on the searches page
    And ".discerner" should contain text "Search should have at least one search criteria."

    When I select dictionary "Sample dictionary"
    And I press "Search"
    Then I should be on the searches page
    And ".discerner" should contain text "Search should have at least one search criteria."

    When I select dictionary "Sample dictionary"
    And I press "Search"
    Then I should be on the searches page
    And ".discerner" should contain text "Search should have at least one search criteria."

  @javascript
  Scenario: It should save created search and redirect to edit page
    Given I create search with name "Awesome search"
    Then I should be on the search edit page
    And "div.discerner_search_name" should contain text "Awesome search"
    And "div.discerner_search_dictionary" should contain text "Sample dictionary"
    And the element ".add_search_parameters" should be visible
    And the element ".discerner_dictionary_required_message" should not be visible

  @javascript
  Scenario: It should not allow to add multiple search criteria with same exclusive parameter
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I select "Age at case collection date" search criteria
    Then the search should have 1 criteria

    When I follow "Add criteria"
    When I open criteria dropdown
    And I follow "Age at case collection date" within the last ".search_parameter"
    Then the element ".div-category-popup" should be visible
    And the last search criteria should not be "Age at case collection date"

  @javascript
  Scenario: It should allow to add multiple search criteria with same not exclusive parameter
    Given search dictionaries are loaded
    And search operators are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I select "Text search diagnosis" search criteria
    Then the search should have 1 criteria

    When I follow "Add criteria"
    When I open criteria dropdown
    And I follow "Text search diagnosis" within the last ".search_parameter"
    Then the element ".div-category-popup" should not be visible
    And ".parameter input.ui-autocomplete-input" in the last ".search_parameter" should contain "Case criteria - Text search diagnosis"

  @javascript
  Scenario: It should pre-select search dictionary if there is only one available
    Given search dictionaries are loaded
    And only "Sample dictionary" dictionary exists
    When I go to the new search page
    Then "div.discerner_search_name" should contain text "Search name"
    And "div.discerner_search_dictionary" should contain text "Sample dictionary"
    And the element ".add_search_parameters" should be visible
    And the element ".discerner_dictionary_required_message" should not be visible
    And I select "Gender" search criteria
    And I wait 1 seconds
    And I check "input[type='checkbox']" within the first ".search_parameter .chosen"
    When I press "Search"
    Then I should be on the search edit page
    And "div.discerner_search_dictionary" should contain text "Sample dictionary"

  @javascript
  Scenario: It should notify user if there are no searches that can be combined
    Given search dictionaries are loaded
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    Then ".search_combinations" should contain text "No qualifying searches found"

  @javascript
  Scenario: It should not allow to add combined searches until dictionary is selected
    Given I create search with name "Awesome search"
    When I go to the new search page
    Then the element ".add_search_combinations" should not be visible
    When I select dictionary "Sample dictionary"
    Then the element ".add_search_combinations" should be visible

  @javascript
  Scenario: It should allow to add combined searches if dictionary is selected
    Given I create search with name "Awesome search"
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    Then ".combined_search_operator" in the first ".search_combination" should contain text "restrict to"
    And ".remove" in the first ".search_combination" should contain text "Remove"

  @javascript
  Scenario: It should filter combined searches by selected dictionary
    Given I create search for dictionary "Sample dictionary" with name "Awesome search"
    And I create search for dictionary "Librarian dictionary" with name "Book search"

    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I open combined search dropdown
    Then ".combined_search select" in the first ".search_combination" should have options "Awesome search"
    And ".combined_search select" in the first ".search_combination" should not have options "Book search"

    When I select dictionary "Librarian dictionary"
    And I open combined search dropdown
    Then ".combined_search select" in the first ".search_combination" should not have options "Awesome search"
    And ".combined_search select" in the first ".search_combination" should have options "Book search"

  @javascript
  Scenario: It should allow to select combined search from the list
    Given I create search with name "Awesome search"
    And I create search with name "Another search"
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I fill in "input.search_combinations_combobox_autocompleter" autocompleter within the first ".search_combination" with "Awesome search"
    And I select "Gender" search criteria
    And I press "Search"
    Then ".combined_search select" in the first ".search_combination" should have "Awesome search" selected
    And ".combined_search select" in the first ".search_combination" should not have "Another search" selected

  @javascript
  Scenario: Deleted parameter values should not be given as options
    Given search dictionaries are loaded
    And value "Unknown" for parameter "Gender" is marked as deleted
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I select "Gender" search criteria
    Then ".parameter_values" in the first ".search_parameter" should contain text "Male"
    And ".parameter_values" in the first ".search_parameter" should not contain text "Unknown"

  @javascript
  Scenario: Deleted parameters should not be given as parameters options
    Given search dictionaries are loaded
    And parameter "Gender" is marked as deleted
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I open criteria dropdown
    Then ".parameter select" in the first ".search_parameter" should have options "Demographic criteria - Age at case collection date, Demographic criteria - Ethnic group, Demographic criteria - Race, Case criteria - Text search diagnosis"
    And ".parameter select" in the first ".search_parameter" should not have options "Demographic criteria - Gender"

  @javascript
  Scenario: Deleted categories should not be shown in parameters options
    Given search dictionaries are loaded
    And parameter category "Case criteria" is marked as deleted
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I open criteria dropdown
    Then ".div-category-list" should not contain text "Case criteria"

  @javascript
  Scenario: Categories with all parameters disabled should not be shown in parameters options
    Given search dictionaries are loaded
    And parameters in category "Case criteria" are marked as deleted
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I open criteria dropdown
    Then ".div-category-list" should not contain text "Case criteria"

  @javascript
  Scenario: Deleted dictionaries should not be given as dictionary options
    Given search dictionaries are loaded
    And dictionary "Sample dictionary" is marked as deleted
    When I go to the new search page
    Then "div.discerner_search_name" should contain text "Search name"
    And "div.discerner_search_dictionary" should contain text "Librarian dictionary"

  @javascript
  Scenario: Deleted searches should not be given as combined search options
    Given I create search with name "Awesome search"
    And search with name "Awesome search" is marked as deleted
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    Then ".search_combinations" should contain text "No qualifying searches found"

  @javascript
  Scenario: Disabled searches should not be given as combined search options
    Given search dictionaries are loaded
    And search operators are loaded
    And search "best search ever" exists
    And search "best search ever" is disabled
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    Then ".search_combinations" should contain text "No qualifying searches found"


