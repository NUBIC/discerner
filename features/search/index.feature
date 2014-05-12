Feature: Viewing existing searches
  A user should be able view existing searches

  Scenario: Viewing existing searches
    Given search dictionaries are loaded
    And search "best search ever" exists
    And search "another search" exists
    When I go to the searches page
    Then "#searches-list" should contain text "best search ever"
    And "#searches-list" should contain text "another search"

  @javascript
  Scenario: Filtering existing searches
    Given search dictionaries are loaded
    And search "best search ever" exists
    And search "another search" exists
    When I go to the searches page
    And I fill in "Filter by name" with "best"
    And I wait 2 seconds
    Then "#searches-list" should contain text "best search ever"
    And "#searches-list" should not contain text "another search"
    When I fill in "Filter by name" with "another"
    And I wait 2 seconds
    Then "#searches-list" should not contain text "best search ever"
    And "#searches-list" should contain text "another search"

  @javascript
  Scenario: Deleting searches
    Given search dictionaries are loaded
    And search "best search ever" exists
    And search "another search" exists
    When I go to the searches page
    And I confirm "Delete" within the first "tr.odd_record"
    Then I should be on the searches page
    Then "#searches-list" should contain text "best search ever"
    And "#searches-list" should not contain text "another search"

  @javascript
  Scenario: Viewing disabled searches
    Given search dictionaries are loaded
    And search "best search ever" exists
    And search "best search ever" is disabled
    When I go to the searches page
    Then "#searches-list .error" should contain text "best search ever"

  @javascript
  Scenario: Viewing combined searches
    Given I create search with name "Awesome search"
    And I create search with name "Another search"
    When I go to the search edit page
    And I add combined search
    And I press "Search"
    When I go to the searches page
    Then "#searches-list" should contain text "Awesome search"
    And "#searches-list" should contain text "Another search"

