Feature: Viewing existing searches
  A user should be able view existing searches

  Scenario: Vieving existing searches
    Given search dictionaries are loaded
    And search "best search ever" exists
    And search "another search" exists
    When I go to the searches page
    Then "searches-list" should contain text "best search ever"
    And "searches-list" should contain text "another search"

  @javascript
  Scenario: Filtering existing searches
    Given search dictionaries are loaded
    And search "best search ever" exists
    And search "another search" exists
    When I go to the searches page
    And I fill in "Filter by name" with "best"
    And I wait 2 seconds
    Then "searches-list" should contain text "best search ever"
    And "searches-list" should not contain text "another search"
    When I fill in "Filter by name" with "another"
    And I wait 2 seconds
    Then "searches-list" should not contain text "best search ever"
    And "searches-list" should contain text "another search"

  @javascript
  Scenario: Deleting searches
    Given search dictionaries are loaded
    And search "best search ever" exists
    And search "another search" exists
    When I go to the searches page
    And I confirm "Delete" within the first "tr.odd_record" 
    Then I should be on the searches page
    Then "searches-list" should not contain text "best search ever"
    And "searches-list" should contain text "another search"
  