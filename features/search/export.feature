Feature: Exporting results for existing searches
  A user should be able to export search results

  @javascript
  Scenario: It should show export link
    Given I create search with name "Awesome search"
    When I am on the search edit page
    Then ".discerner-buttons" should contain text "Export options"
    When I follow "Export options"
    Then I should be on the search export page

  @javascript
  Scenario: It should not display deleted parameters as export options unless they are checked
    Given I create search with name "Awesome search"
    And search with name "Awesome search" has exportable parameters "Gender"
    And parameter "Age based on current date" is marked as deleted
    When I am on the search export page
    Then ".discerner" should not contain text "There is an issue with the this export that has to be corrected before it can be executed"
    And "#discerner_exportable_fields" should not contain text "Age based on current date"

  @javascript
  Scenario: It should display and highlight deleted parameters as export options if they are checked
    Given I create search with name "Awesome search"
    And search with name "Awesome search" has exportable parameters "Gender, Age based on current date"
    And parameter "Age based on current date" is marked as deleted
    When I am on the search export page
    Then ".discerner" should contain text "There is an issue with the this export that has to be corrected before it can be executed"
    And "#discerner_exportable_fields .error" should contain text "Age based on current date"

  @javascript
  Scenario: It should not allow to export search that uses disabled parameter values for searching
    Given I create search with name "Awesome search"
    And value "Female" for parameter "Gender" is marked as deleted
    When I am on the search export page
    Then ".discerner" should contain text "There is an issue with the this export that has to be corrected before it can be executed"
    And ".discerner-buttons" should not contain text "Export"
    And ".discerner" should not contain text "Fields to be exported"

  @javascript
  Scenario: It should not allow to export search that uses disabled parameters for searching
    Given I create search with name "Awesome search"
    And parameter "Gender" is marked as deleted
    When I am on the search export page
    Then ".discerner" should contain text "There is an issue with the this export that has to be corrected before it can be executed"
    And ".discerner-buttons" should not contain text "Export"
    And ".discerner" should not contain text "Fields to be exported"

  @javascript
  Scenario: It should not allow to export search that uses disabled combined searches for searching
    Given I create search with name "Awesome search"
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I add combined search
    And I fill in "input.search_combinations_combobox_autocompleter" autocompleter within the first ".search_combination" with "Awesome search"
    And I add "Gender" search criteria
    And I press "Search"
    And search with name "Awesome search" is marked as deleted
    When I am on the search export page
    Then ".discerner" should contain text "There is an issue with the this export that has to be corrected before it can be executed"
    And ".discerner-buttons" should not contain text "Export"
    And ".discerner" should not contain text "Fields to be exported"

  @javascript
  Scenario: It should not allow to export search that uses disabled parameters for export
    Given I create search with name "Awesome search"
    And search with name "Awesome search" has exportable parameters "Age based on current date, Gender"
    And parameter "Age based on current date" is marked as deleted
    When I am on the search export page
    Then ".discerner" should contain text "There is an issue with the this export that has to be corrected before it can be executed"
    And "#discerner_exportable_fields" should contain text "Age based on current date"
    And the "Age based on current date" checkbox should be checked
    And ".discerner-buttons" should not contain text "Export"
    And ".discerner-buttons" should not contain text "Update and export"
    And ".discerner" should contain text "Fields to be exported"

  @javascript
  Scenario: It should allow to export search that uses disabled parameters for export after they get unchecked
    Given I create search with name "Awesome search"
    And search with name "Awesome search" has exportable parameters "Age based on current date, Gender"
    And parameter "Age based on current date" is marked as deleted
    When I am on the search export page
    And I uncheck "Age based on current date"
    And I press "Update and export"
    Then I should receive a ".xls" file with name "awesome_search_"

  @javascript
  Scenario: It should show search parameters summary
    Given I create search with name "Awesome search"
    When I am on the search export page
    Then "#discerner_search_summary" should contain text "Demographic criteria"
    And "#discerner_search_summary" should not contain text "Case criteria"
    And "#discerner_search_summary" should not contain text "Age at case collection date"
    And "#discerner_search_summary" should contain text "Female"
    And "#discerner_search_summary" should contain text "is equal to "2012-10-22""
    And "#discerner_search_summary" should not contain text "Male"
    And "#discerner_search_summary" should not contain text "Unspecified"

  @javascript
  Scenario: It should show combined searches summary
    Given I create combined search with name "Awesome combined search"
    When I am on the search export page
    Then "#discerner_search_summary" should contain text "Awesome search"

  Scenario: It should return an XLS document named after search
    Given exportable search "Awesome search" exists
    And an executed search should pass the username to dictionary instance
    And an exported search should pass the username to dictionary instance
    When I am on the search edit page
    And I follow "Export options"
    And I press "Export"
    Then I should receive a ".xls" file with name "awesome_search_"

  Scenario: It should allow to export unnamed searches
    Given exportable search "" exists
    When I am on the search edit page
    And I follow "Export options"
    And I press "Export"
    Then I should receive a ".xls" file with name "no_name_specified_"

  @javascript
  Scenario: It should pre-select export options based on search parameters
   Given I create search with name "Awesome search"
    When I am on the search export page
    And the "Gender" checkbox should be checked
    And the "Date of birth" checkbox should be checked

  @javascript
  Scenario: It should pre-select export options based on combined searches parameters
    Given I create search for dictionary "Sample dictionary" with name "Awesome search"
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I add combined search
    And I fill in "input.search_combinations_combobox_autocompleter" autocompleter within the first ".search_combination" with "Awesome search"
    And I add "Race" search criteria
    And I wait 1 seconds
    And I check "input[type='checkbox']" within the first ".search_parameter .chosen"
    And I press "Search"
    And I follow "Export options"
    Then the "Gender" checkbox should be checked
    And the "Date of birth" checkbox should be checked
    And the "Race" checkbox should be checked

  @javascript
  Scenario: It should allow to change and save export parameters
    Given I create search with name "Awesome search"
    When I am on the search export page
    And I uncheck "Date of birth"
    And I check "Age based on current date"
    And I press "Export"
    And I follow "Back to search"
    And I follow "Export"
    Then the "Date of birth" checkbox should not be checked
    And the "Gender" checkbox should be checked
    And the "Age based on current date" checkbox should be checked

  @javascript
  Scenario: It should allow to change and save export parameters for combined searches
    Given I create search for dictionary "Sample dictionary" with name "Awesome search"
    When I go to the new search page
    And I select dictionary "Sample dictionary"
    And I add combined search
    And I fill in "input.search_combinations_combobox_autocompleter" autocompleter within the first ".search_combination" with "Awesome search"
    And I add "Race" search criteria
    And I wait 1 seconds
    And I check "input[type='checkbox']" within the first ".search_parameter .chosen"
    And I press "Search"
    And I follow "Export options"
    And I check "Age based on current date"
    And I uncheck "Date of birth"
    And I uncheck "Race"
    And I press "Export"
    And I follow "Back to search"
    And I follow "Export"
    Then the "Date of birth" checkbox should not be checked
    And the "Race" checkbox should not be checked
    And the "Age based on current date" checkbox should be checked
    And the "Gender" checkbox should be checked

