Feature: Exporting results for existing searches
  A user should be able to export search results

  @javascript
  Scenario: It should show export link
    Given I create search with name "Awesome search"
    When I am on the search edit page
    Then "discerner-buttons" should not contain text "Export options"
    When I follow "Export options"
    Then I should be on the search export page

  @javascript
  Scenario: It should show search parameters summary
    Given I create search with name "Awesome search"
    When I am on the search export page
    Then "discerner_search_summary" should contain text "Demographic criteria"
    And "discerner_search_summary" should not contain text "Case criteria"
    And "discerner_search_summary" should not contain text "Age at case collection date"
    And the "Gender" checkbox should be checked
    And the "Date of birth" checkbox should be checked
    And "discerner_search_summary" should contain text "Gender: "Female""
    And "discerner_search_summary" should contain text "Date of birth: is equal to "2012-10-22""
    And "discerner_exportable_fields" should not contain text "Male"
    And "discerner_exportable_fields" should not contain text "Unspecified"

  @javascript
  Scenario: It should show combined searches summary
    Given I create combined search with name "Awesome combined search"
    When I am on the search export page
    Then "discerner_search_summary" should contain text "Awesome search"

  Scenario: It should return an XLS document named after search
    Given exportable search "Awesome search" exists
    And an executed search should pass the username to dictionary instance
    And an exported search should pass the username to dictionary instance
    When I am on the search edit page
    And I follow "Export"
    And I press "Export"
    Then I should receive a XLS file "awesome_search_"

  Scenario: It should allow to export unnamed searches
    Given exportable search "" exists
    When I am on the search edit page
    And I follow "Export"
    And I press "Export"
    Then I should receive a XLS file "no_name_specified_"

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