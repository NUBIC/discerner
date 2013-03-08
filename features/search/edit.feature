Feature: Viewing existing searches
  A user should be able to edit a search

  @javascript
  Scenario: It should load saved search
    Given I create search with name "Awesome search"
    When I am on the search edit page
    Then the first search criteria should be "Gender"
    And the last search criteria should be "Date of birth"
    And the last search criteria selection value should be "2012-10-22"
    Then "div.discerner_search_name" should contain text "Awesome search"
    And "div.discerner_search_dictionary" should contain text "Sample dictionary"
    And the element ".add_search_parameters" should be visible
    And the element ".discerner_dictionary_required_message" should not be visible

  @javascript
  Scenario: It should render results template
    Given I create search with name "Awesome search"
    When I am on the search edit page
    Then "#discerner_results" should contain text "Results for search on the `Sample dictionary` dictionary can be added here"

  @javascript
  Scenario: It should allow to rename the saved search
    Given I create search with name "Awesome search"
    When I am on the search edit page
    Then "div.discerner_search_name" should contain text "Edit"

    When I follow "Edit"
    And I fill in "search_name" with "Not that great after all"
    And I follow "Cancel"
    Then "div.discerner_search_name" should contain text "Awesome search"
    And "div.discerner_search_name" should not contain text "Cancel"

    When I follow "Edit"
    And I fill in "search_name" with ""
    And I press "Submit"
    Then "div.discerner_search_name" should not contain text "Awesome search"
    And "div.discerner_search_name" should not contain text "Cancel"

    When I follow "Edit"
    And I fill in "search_name" with "Not so awesome search"
    And I press "Submit"
    Then "div.discerner_search_name" should contain text "Not so awesome search"
    And "div.discerner_search_name" should not contain text "Cancel"

  @javascript
  Scenario: It should allow to add and remove search criteria
    Given I create search with name "Awesome search"
    When I am on the search edit page
    And I add "Text search diagnosis" search criteria
    And I enter value "adenocarcinoma" within the last search criteria
    And I press "Search"
    Then ".discerner" should contain text "Search was successfully updated."
    And the last search criteria should be "Text search diagnosis"
    And the last search criteria selection value should be "adenocarcinoma"

    When I follow "Remove" within the last ".search_parameter > .remove"
    And I press "Search"
    Then ".discerner" should contain text "Search was successfully updated"
    And the last search criteria should be "Date of birth"
    And the last search criteria selection value should be "2012-10-22"

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
  Scenario: It should allow to add and remove combined search from the list
    Given I create search with name "Awesome search"
    And I create search with name "Another search"

    When I go to the search edit page
    And I add combined search
    And I fill in "input.autocompleter-dropdown" autocompleter within the first ".search_combination" with "Awesome search"
    And I add "Text search diagnosis" search criteria
    And I enter value "adenocarcinoma" within the last search criteria
    And I press "Search"
    Then ".combined_search select" in the first ".search_combination" should have "Awesome search" selected
    And ".combined_search select" in the first ".search_combination" should not have "Another search" selected

  @javascript
  Scenario: It should not allow to combine in searches that use the search
    Given I create search with name "Awesome search"
    And I create search with name "Another search"
    And I create search with name "One more search"
    When I go to the search "Another search" edit page
    And I add combined search
    And I fill in "input.autocompleter-dropdown" autocompleter within the first ".search_combination" with "Awesome search"
    And I add "Text search diagnosis" search criteria
    And I enter value "adenocarcinoma" within the last search criteria
    And I press "Search"
    And I go to the search "Awesome search" edit page
    And I add combined search
    And I open combined search dropdown
    Then ".combined_search select" in the first ".search_combination" should not have options "Another search"
    And ".combined_search select" in the first ".search_combination" should have options "One more search"

  @javascript
  Scenario: Deleted parameter values should not be given as options if they are not selected
    Given I create search with name "Awesome search"
    And value "Unknown" for parameter "Gender" is marked as deleted
    When I go to the search edit page
    Then ".search_parameter_values" in the first ".search_parameter" should contain text "Male"
    And ".search_parameter_values" in the first ".search_parameter" should not contain text "Unknown"

  @javascript
  Scenario: Deleted parameter values should be given as options if they are selected
    Given I create search with name "Awesome search"
    And value "Female" for parameter "Gender" is marked as deleted
    When I go to the search edit page
    Then ".search_parameter_values" in the first ".search_parameter" should contain text "Female"

  @javascript
  Scenario: Deleted parameter values should be highlighted if they are selected
    Given I create search with name "Awesome search"
    And value "Female" for parameter "Gender" is marked as deleted
    When I go to the search edit page
    Then ".error" in the first ".search_parameter_values" should contain text "Female"

  @javascript
  Scenario: It should remove deleted value from the options after it gets unchecked
    Given I create search with name "Awesome search"
    And value "Female" for parameter "Gender" is marked as deleted
    When I go to the search edit page
    And I uncheck "input[type='checkbox']" within the first ".search_parameter .chosen"
    And I press "Update search"
    Then ".search_parameter_values" in the first ".search_parameter" should not contain text "Female"

  @javascript
  Scenario: Deleted parameters should not be given as options if they are not selected
    Given I create search with name "Awesome search"
    And parameter "Text search diagnosis" is marked as deleted
    When I go to the search edit page
    Then ".parameter select" in the last ".search_parameter" should not have options "Text search diagnosis"

  @javascript
  Scenario: Deleted parameters should be given as options if they are selected
    Given I create search with name "Awesome search"
    And parameter "Gender" is marked as deleted
    When I go to the search edit page
    Then ".parameter select" in the last ".search_parameter" should have options "Gender"

  @javascript
  Scenario: Deleted parameters should be highlighted if they are selected
    Given I create search with name "Awesome search"
    And parameter "Gender" is marked as deleted
    When I go to the search edit page
    Then ".search_parameters .error select" should have options "Gender"

  @javascript
  Scenario: Deleted searches should not be given as options if they are not selected
    Given search "Awesome search" combines in search "Another search"
    And I create search with name "One more search"
    And search with name "One more search" is marked as deleted
    When I go to the search "Awesome search" edit page
    Then ".combined_search select" should not have options "One more search"

  @javascript
  Scenario: Deleted searches should be given as options if they are selected
    Given search "Awesome search" combines in search "Another search"
    And search with name "Another search" is marked as deleted
    When I go to the search "Awesome search" edit page
    Then ".combined_search select" should have options "Another search"

  @javascript
  Scenario: Deleted searches should be highlighted if they are selected
    Given search "Awesome search" combines in search "Another search"
    And search with name "Another search" is marked as deleted
    When I go to the search "Awesome search" edit page
    Then ".search_combinations .error select" should have options "Another search"

  @javascript
  Scenario: Disabled searches should not be given as options if they are not selected
    Given search "Awesome search" combines in search "Another search"
    And I create search with name "One more search"
    And search "One more search" is disabled
    When I go to the search "Awesome search" edit page
    Then ".combined_search select" should not have options "One more search"

  @javascript
  Scenario: Disabled searches should be given as options if they are selected
    Given search "Awesome search" combines in search "Another search"
    And search "Another search" is disabled
    When I go to the search "Awesome search" edit page
    Then ".combined_search select" should have options "Another search"

  @javascript
  Scenario: Disabled searches should be highlighted if they are selected
    Given search "Awesome search" combines in search "Another search"
    And search "Another search" is disabled
    When I go to the search "Awesome search" edit page
    Then ".combined_search select" should have options "Another search"

  @javascript
  Scenario: It should not show export link if search is disabled
    Given I create search with name "Awesome search"
    And value "Female" for parameter "Gender" is marked as deleted
    When I am on the search edit page
    Then ".discerner-buttons" should not contain text "Export options"
