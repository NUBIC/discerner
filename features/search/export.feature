Feature: Exporting results for existing searches
  A user should be able to export search results

  @javascript
  Scenario: It should show export link
    Given I create search with name "Awesome search" 
    When I am on the search edit page
    Then I should see "Export"
    When I follow "Export"
    Then I should be on the search export page

  @javascript
  Scenario: It should show search parameters summary
    Given I create search with name "Awesome search" 
    When I am on the search export page
    Then I should see "Demographic criteria"
    And I should not see "Case criteria"
    And I should not see "Age at case collection date"
    And the "Gender" checkbox should be checked
    And the "Date of birth" checkbox should be checked
    And I should see "Gender: "Female""
    And I should not see "Male"
    And I should not see "Unspecified"
    And I should see "Date of birth: is equal to "2012-10-22""

  @javascript
  Scenario: It should show combined searches summary
    Given I create combined search with name "Awesome combined search" 
    When I am on the search export page
    Then I should see "Awesome search"

  Scenario: It should return a CSV document named after search
    Given exportable search "Awesome search" exists
    When I am on the search edit page
    And I follow "Export"
    And I press "Export"
    Then I should receive a CSV file "awesome_search_"

  Scenario: It should allow to export unnamed searches
    Given exportable search "" exists
    When I am on the search edit page
    And I follow "Export"
    And I press "Export"
    Then I should receive a CSV file "no_name_specified_"

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