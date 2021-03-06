Discerner History
============
2.0.15 07/14/2015
-----
- Exclusive lists of parameter values UI: values not removed on parameter change
See https://github.com/NUBIC/discerner/issues/23
- Remove default sorting on list of export parameters
See https://github.com/NUBIC/discerner/issues/24

2.0.14
-----
- Updated dependency on jquery-rails to support 4.0.x versions

2.0.13 3/11/2015
-----

* Rendering of checkbox lists does not work on IE9.
See https://github.com/NUBIC/discerner/issues/15

2.0.12 3/11/2015
-----

* Categorized autocompleter is blowing up.
See https://github.com/NUBIC/discerner/issues/19

* Make compatible with Rails 4.2
See https://github.com/NUBIC/discerner/issues/18

2.0.11
-----
- Merged rails4 branch into master.
- Allow to define if parameter should be hidden in search and/or export.
- Hide selected hidden export parameters from UI.
- Fixed bug with calculating display order.
- Added 'last_executed' timestamp to Discerner::Search. This timestamp is ser by controller edit action after executing the search.

2.0.10
-----
- Do not use asset_path with image_tag.
- Update search datestamp when search parameters/parameter_values get updated.

2.0.9
-----
- Show an spinner upon loading of an autocompleting combobox.
- Improve the performance of the rendering of large lists of values in autocompleting comboboxes.
- Remove !important declaration from CSS to allow overriding.

2.0.8
-----
- Use asset_url helper for images.
- Include jQueryUI assets into discerner assets.

2.0.7
-----
- Do not delete parameters. categories, values for dictionaries that are not defined in parsed file, unless —prune-dictionaries parameter is set.

2.0.6
-----
- Added task to delete dictionary by name.
- Do not delete dictionaries that are not in definition file unless -—prune_dictionaries parameter is specified.
2.0.5
-----
- Allow to assign Discerner::Search to multiple namespaces. This change rolls back namespacing on search object itself. Previously set namespaces will be either mapped to new Discerner::Search namespace if they have namespace_id specified, or replaced with ‘label’ if they don’t.
- Namespace helper methods

2.0.4
-----
- Revert previous change. We expect namespaces to be outside entities and storimg IDs that would most likely be domain-specific in a static file is not the best idea.

2.0.3
-----
- Allow to parse dictionary namespace type and namespace id.

2.0.2
-----
- Back to jquery-ui-rails 4.2

2.0.1
-----
- Updated hash syntax to 2.1
- Allow to namespace searches and dictionaries
- Using Rails 4.1

2.0.0
-----
- Rails 4 support

1.2.0
-----
- Show an spinner upon loading of an autocompleting combobox.
- Improve the performance of the rendering of large lists of values in autocompleting comboboxes.

1.1.20
-----
- Added discerner schema image.
- Replaced ajax-based filter for saved searches with regular form.
- Ignore YARD documentation files.
- Changed YARD output directory.
- Added status badge to README file.

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
