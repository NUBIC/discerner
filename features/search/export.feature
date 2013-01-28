Feature: Exporting results for existing searches
  A user should be able to export search results

  @javascript
  Scenario: In should allow to export search results
    Given I create search with name "Awesome search" 
    When I am on the search edit page
    Then I should see "Export"
    
    When I follow "Export"
    Then I should see "Case criteria"
    And the "Date of birth" checkbox should be checked
    And the "Gender" checkbox should be checked
    And I should see "Gender: Female"
    And I should not see "Male"
    And I should not see "Unspecified"
    And I should see "Date of birth: is equal to 2012-10-22 "