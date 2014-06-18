Discerner History
============
1.1.19
-----
- Require jquery-rails and jquery-ui-rails.
- Updated documentation.
- Removed NUBIC dependencies.
- Updated gem summary and description.

1.1.18
-----
- Assign user when search is created and do not update it through the form.

1.1.17
-----
- Increase performance of loading of autocompleter lists for paramater values.

1.1.16
-----
- Fixed bug with sorting not maintained while filtering searches by name.

1.1.15
-----
- Fixed bug with scoping export parameters by parameter category.

1.1.14
-----
- Refactored the way export parameters and search parameter values are ordered for display.

1.1.13
-----
- Refactored ordering, added scopes for frequently used order statements, specified table names in sorting statements.
- Added 'by_parameter_category' scope to export_parameters

1.1.12
-----
- Fixed bug with search parameters and search parameter categories from other dictionaries showing up in the edit page of a search.

1.1.11
-----
- Refactored parameters drop-down: sort categories and parameters alphabetically

1.1.10
-----
- Specified table name in sorting conditions for search index page.
- Renamed “Search Summary” to “Search criteria”

1.1.9
-----
- Extracted warnings logic from Search, SearchParameter and SearchParameterValue into Warnings module.
- Do not store search_parameter_value value if presence operator is selected.
- Fixed spec for searches index that got broken after ordering got changed.
- Refactored validations. Added inverse_of specifications whenever is applicable.
- More code refactoring, reduced number of database requests.
- Search parameter combo box watermark: replaced ‘question’ with ‘criteria’
- Removed unused builders from discerner controller
- Automatically initiate search criteria and combined search options when new search is started.
- Extracted search control buttons into a partial that can be overriden by host application

1.1.8
-----
- Fixed bug with searches being ambiguously ordered by id column. Specified discerner_searches relation and updated_at columns to be used for ordering, so recent searches will stay on top of the list.

1.1.7
-----
- Merged master and rails3.2 branches

1.1.6
-----
- Fixed bug with missing error for 'combobox' search parameters without selected parameter values

1.1.5
-----
- Fixed bug with missing error for 'list' search parameter without selected parameter values

1.1.4
-----
- Fixed bug with 'Uncategorised' parameter value group displayed even when there are no uncategorized parameter values in the dictionary.

1.1.3
-----
- Hide "Export parameters" link from the searches list if exporting is disabled

1.1.2
-----
- Fixed bug with dictionary being deleted after parcing error

1.0.2
-----
* Fixed bug with dictionary being deleted after parcing error

1.0.1
-----
- Dropping support for ruby 1.8.7

1.0.0
-----
- Bumped version
