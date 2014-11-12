# Discerner

Discerner is an engine for Rails that provides basic search UI, search reqults export UI and allows to configure available search parameters/values. Discerner is not aimed to be a SQL-generator, but it allows the host application to access stored search conditions and provide search results.

Reader's note: this README uses [YARD][] markup to provide links to
Discerner's API documentation. If you aren't already, consider reading it
on [rubydoc.info][] so that the links will be followable.

[YARD]: http://yardoc.org/
[rubydoc.info]: http://rubydoc.info/github/NUBIC/discerner/master/file/README.md

## Status
[![Gem Version](https://badge.fury.io/rb/discerner.svg)](http://badge.fury.io/rb/discerner)

# Requirements

This code has been run and tested on Ruby 1.9. and Ruby 2.1

# Dependencies

* haml
* sass
* jquery-rails

# Installation

## Install gem with Bundler

```ruby
gem 'discerner'
bundle install
```
## Run the installer

```ruby
rails generate discerner:install
```

By default, Discerner installer performs following tasks:

* it copies Discerner's migrations into db/migrate and runs migrations
* it sets up default Discerner operators. As of now, default operators cannot be changed.
* it prompts for current_user helper name and inserts `discerner_user` method into the application controller. This allows Discerner to attibure created searches to the current user.
* it adds discerner helpers used for configuring dicerner functionality into application helper. This will be changed in the future.
  * show_discerner_results? - helper used to determine if search results should be displayed.
  * export_discerner_results? - helper used to determine if search results should be exportable.
  * enable_combined_searches? - helper used to determine if search interface should allow to combine searches
* it mounts Discerner::Engine
* it copies sample search dictionary into lib/setup

Discerner installer accepts following parameters:

* --no-migrate - prevent installer from running migrations. If this flag is set, Discerner operators would have to be loaded manually using **rake discerner:setup:operators**
* --current-user-helper   - allows to specify current user method name
* --customize-controllers - copy Discerner controllers into application, so they can be customized
* --customize-models      - copy Discerner models into application, so they can be customized
* --customize-helpers     - copy Discerner helpers into application, so they can be customized
* --customize-layout      - copy Discerner layout into application, so it can be customized
* --customize-all         - copy Discerner controllers, models, helpers, and layout into application, so they can be customized


# Usage
## Setting up dictionaries

```ruby
rails generate discerner:dictionary [FILENAME]
```
Discerner uses dictionaries to define parameters and values that can be used for constructing searches. Discerner dictionary generator performs following tasks:

* it parses provided file and sets up or updates corresponding search dictionary, its parameter categories, parameters and parameter values
* it creates a model for each specified dictionary that is expected to implement "search" and "export" methods.
* it generates template views for search results and export.

Discerner dictionary generator accepts following parameters:

* --no-load   - skip dictionary generation/update
* --no-models - skip models generation
* --no-views  - skip views generation

Installer adds a sample dictionary than can be used as a template anr/or can be parsed and used to explore Discerner Search UI:

```ruby
rails generate discerner:dictionary lib/setup/dictionaries.yml
```

## Updating dictionaries

In most cases, dictionary generator needs to be run only once per dictionary. Dictionary updates, excluding name change, should be handled by re-parcing definition file with Discerner parser:

```ruby
rails discerner:setup:dictionaries FILE=xxx
```

Discerner parser processes YML definition file line by line, detecting and creating/updating dictionaries, parameter categories, parameters and parameter values. It runs in silent mode by default, --trace option can be used to make it verbose.

## User Interface

Index of all saved searches scoped by current user (if available) can be accessed from '/searches' route.

