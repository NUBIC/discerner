require 'spec_helper'

describe Discerner::Parser do
  it "parses operators" do
    file = 'lib/setup/operators.yml'
    parser = Discerner::Parser.new(trace: true)
    parser.parse_operators(File.read(file))

    expect(Discerner::Operator.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterType.order(:id).to_a).to_not be_empty
  end

  it "parses dictionaries" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new()
    parser.parse_dictionaries(File.read(file))

    expect(Discerner::Dictionary.order(:id).to_a).to_not be_empty
    expect(Discerner::Dictionary.order(:id).to_a.length).to eq 2

    dictionary = Discerner::Dictionary.find_by_name('Sample dictionary')
    expect(dictionary).to_not be_blank
    expect(dictionary.parameter_categories.length).to eq 2
    expect(dictionary.searchable_categories.length).to eq 2
    expect(dictionary.exportable_categories.length).to eq 1
    expect(dictionary).to_not be_deleted

    expect(dictionary.parameter_categories.first.parameters.length).to eq 7
    expect(dictionary.parameter_categories.first.searchable_parameters.length).to eq 6
    expect(dictionary.parameter_categories.first.exportable_parameters.length).to eq 4
    expect(dictionary.parameter_categories.first).to_not be_deleted

    expect(dictionary.parameter_categories.last.parameters.length).to eq 2
    expect(dictionary.parameter_categories.last).to_not be_deleted

    expect(dictionary.parameter_categories.first.parameters.where(unique_identifier: 'ethnic_grp').first.parameter_values.length).to eq 5 # extra 'None' value added
  end

  it "parses parameters with source model and method" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :source:
                    :model: Patient
                    :method: ethnic_groups
    }
    parser.parse_dictionaries(dictionaries)

    expect(Discerner::Dictionary.order(:id).to_a).to_not be_empty
    expect(Discerner::Dictionary.order(:id).to_a.length).to eq 1
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 1
    p = Discerner::Parameter.last
    expect(p.name).to eq 'Ethnic group'

    ethnic_groups_names = Patient.ethnic_groups.map { |ethnic_group| ethnic_group[:name] }
    ethnic_groups_search_values = Patient.ethnic_groups.map { |ethnic_group| ethnic_group[:search_value] }
    expect(Set.new(p.parameter_values.map(&:name))).to eq Set.new(ethnic_groups_names + ['None'])
    expect(Set.new(p.parameter_values.map(&:search_value))).to eq Set.new(ethnic_groups_search_values + [''])
  end

  it "parses export parameters" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :export:
                  :model: Patient
                  :method: ethnic_grp
    }
    parser.parse_dictionaries(dictionaries)

    expect(Discerner::Dictionary.all).to_not be_empty
    expect(Discerner::Dictionary.all.length).to eq 1
    expect(Discerner::Parameter.all.length).to eq 1
    p = Discerner::Parameter.last
    expect(p.name).to eq 'Ethnic group'

    expect(Set.new(p.parameter_values.map(&:search_value))).to be_empty
  end

  it "updates export parameters" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :export:
                  :model: Patient
                  :method: ethnic_grp

              - :name: Gender
                :unique_identifier: gender
                :export:
                  :model: Patient
                  :method: gender
    }
    parser.parse_dictionaries(dictionaries)

    expect(Discerner::Dictionary.all).to_not be_empty
    expect(Discerner::Dictionary.all.length).to eq 1
    expect(Discerner::Parameter.all.length).to eq 2

    updated_dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group new
                :unique_identifier: ethnic_grp
                :export:
                  :model: Patient
                  :method: ethnic_grp
    }
    parser = Discerner::Parser.new()
    parser.parse_dictionaries(updated_dictionaries)

    expect(Discerner::Dictionary.all).to_not be_empty
    expect(Discerner::Dictionary.all.length).to eq 1
    expect(Discerner::Parameter.all.length).to eq 1
    p = Discerner::Parameter.last
    expect(p.name).to eq 'Ethnic group new'

    expect(Set.new(p.parameter_values.map(&:search_value))).to be_empty
  end

  it "raises an error message with a source model and method that does not conform to the :name, :search_value interface" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :source:
                    :model: Patient
                    :method: smethnic_groups
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.errors).to eq [": method 'smethnic_groups' does not adhere to the interface"]
    expect(Discerner::Dictionary.order(:id).to_a).to be_empty
  end

  it "does not clean up after encountering errors" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :export:
                  :model: Patient
                  :method: ethnic_grp

              - :name: Gender
                :unique_identifier: gender
                :export:
                  :model: Patient
                  :method: gender
    }
    parser.parse_dictionaries(dictionaries)

    expect(Discerner::Dictionary.all).to_not be_empty
    expect(Discerner::Dictionary.all.length).to eq 1

    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :source:
                    :model: Patient
                    :method: smethnic_groups
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.errors).to eq [": method 'smethnic_groups' does not adhere to the interface"]
    expect(Discerner::Dictionary.all).to_not be_empty
    expect(Discerner::Dictionary.all.length).to eq 1
    expect(Discerner::Dictionary.first).to_not be_deleted
  end

  it "does not clean up after encountering errors" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :export:
                  :model: Patient
                  :method: ethnic_grp

              - :name: Gender
                :unique_identifier: gender
                :export:
                  :model: Patient
                  :method: gender
    }
    parser.parse_dictionaries(dictionaries)

    expect(Discerner::Dictionary.all).to_not be_empty
    expect(Discerner::Dictionary.all.length).to eq 1

    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :source:
                    :model: Patient
                    :method: smethnic_groups
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.errors).to eq [": method 'smethnic_groups' does not adhere to the interface"]
    expect(Discerner::Dictionary.all).to_not be_empty
    expect(Discerner::Dictionary.all.length).to eq 1
    expect(Discerner::Dictionary.first).to_not be_deleted
  end

  it "parses parameters with source attribute method and model" do
    Patient.create(:id=>1, :gender=>'Male')
    Patient.create(:id=>2, :gender=>'Female')
    Patient.create(:id=>3, :gender=>'Female')
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
    - :name: Sample dictionary
      :parameter_categories:
        - :name: Demographic criteria
          :parameters:
            - :name: Gender
              :unique_identifier: gender
              :search:
                :model: Patient
                :method: gender
                :parameter_type: list
                :source:
                  :model: Patient
                  :method: gender
    }
    parser.parse_dictionaries(dictionaries)
    expect(Discerner::Dictionary.order(:id).to_a).to_not be_empty
    expect(Discerner::Dictionary.order(:id).to_a.length).to eq 1
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 1
    p = Discerner::Parameter.last
    expect(p.name).to eq 'Gender'

    genders = Patient.order(:id).to_a.map { |patient| patient.gender }
    expect(Set.new(p.parameter_values.map(&:name))).to eq Set.new(genders + ['None'])
    expect(Set.new(p.parameter_values.map(&:search_value))).to eq Set.new(genders + [''])
  end

  it "restores soft deleted dictionaries if they are defined in the dictionary definition" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new()
    parser.parse_dictionaries(File.read(file))

    count = Discerner::Dictionary.order(:id).to_a.length
    Discerner::Dictionary.order(:id).to_a.each do |d|
      d.deleted_at = Time.now
      d.save
    end

    parser.parse_dictionaries(File.read(file))
    Discerner::Dictionary.order(:id).to_a.each do |d|
      expect(d).to_not be_deleted
    end
    expect(Discerner::Dictionary.order(:id).to_a.length).to eq count
  end

  it "restores soft deleted parameter categories if they defined in the dictionary definition" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new()
    parser.parse_dictionaries(File.read(file))

    Discerner::ParameterCategory.order(:id).to_a.each do |d|
      d.deleted_at = Time.now
      d.save
    end

    parser.parse_dictionaries(File.read(file))
    Discerner::ParameterCategory.order(:id).to_a.each do |d|
      expect(d).to_not be_deleted
    end
  end

  it "restores soft deleted parameters if they are not marked as deleted in the dictionary definition" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new()
    parser.parse_dictionaries(File.read(file))

    Discerner::Parameter.order(:id).to_a.each do |d|
      d.deleted_at = Time.now
      d.save
    end

    parser.parse_dictionaries(File.read(file))
    Discerner::Parameter.order(:id).to_a.each do |d|
      expect(d).to_not be_deleted
    end
  end

  it "parses boolean parameter values" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Consented
                :unique_identifier: consented
                :search:
                  :model: Patient
                  :method: consented
                  :parameter_type: list
                  :parameter_values:
                    - :search_value: yes
                    - :search_value: no
    }
    parser.parse_dictionaries(dictionaries)
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 1
    Discerner::Parameter.last.parameter_values.each do |pv|
      expect(['true', 'false', 'None']).to include(pv.name)
    end
  end

  it "does not add 'None' value if allow_empty_values set to false" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Consented
                :unique_identifier: consented
                :search:
                  :model: Patient
                  :method: gender
                  :parameter_type: list
                  :allow_empty_values: false
                  :parameter_values:
                    - :search_value: Male
                    - :search_value: Female
    }
    parser.parse_dictionaries(dictionaries)
    expect(Discerner::Parameter.all.length).to eq 1
    Discerner::Parameter.last.parameter_values.each do |pv|
      expect(['Male', 'Female']).to include(pv.name)
    end
  end

  it "parses 'hidden' configuration values" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Consented
                :unique_identifier: consented
                :export:
                  :model: Patient
                  :method: consented
                :search:
                  :model: Patient
                  :method: consented
                  :parameter_type: list
                  :allow_empty_values: false
                  :parameter_values:
                    - :search_value: yes
                    - :search_value: no
    }
    parser.parse_dictionaries(dictionaries)
    expect(Discerner::Parameter.all.length).to eq 1
    parameter = Discerner::Parameter.last
    expect(parameter.hidden_in_export).to eq false
    expect(parameter.hidden_in_search).to eq false

    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Another sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Consented
                :unique_identifier: consented
                :export:
                  :model: Patient
                  :method: consented
                  :hidden: true
                :search:
                  :model: Patient
                  :method: consented
                  :parameter_type: list
                  :allow_empty_values: false
                  :hidden: true
                  :parameter_values:
                    - :search_value: yes
                    - :search_value: no
    }
    parser.parse_dictionaries(dictionaries)
    expect(Discerner::Parameter.all.length).to eq 2
    parameter = Discerner::Parameter.last
    expect(parameter.hidden_in_export).to eq true
    expect(parameter.hidden_in_search).to eq true

    dictionaries = %Q{
    :dictionaries:
      - :name: Another sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Consented
                :unique_identifier: consented
                :export:
                  :model: Patient
                  :method: consented
                  :hidden: false
                :search:
                  :model: Patient
                  :method: consented
                  :parameter_type: list
                  :allow_empty_values: false
                  :hidden: false
                  :parameter_values:
                    - :search_value: yes
                    - :search_value: no
    }
    parser.parse_dictionaries(dictionaries)
    expect(Discerner::Parameter.all.length).to eq 2
    parameter = Discerner::Parameter.last
    expect(parameter.hidden_in_export).to eq false
    expect(parameter.hidden_in_search).to eq false

  end

  it "finds and updates moved parameters" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Consented
                :unique_identifier: consented
    }
    parser.parse_dictionaries(dictionaries)
    p = Discerner::Parameter.where(unique_identifier: 'consented').first
    expect(p).to_not be_blank
    expect(p.name).to eq 'Consented'
    expect(p.parameter_category.name).to eq 'Demographic criteria'

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Another criteria
            :parameters:
              - :name: Consented already
                :unique_identifier: consented
    }
    parser.parse_dictionaries(dictionaries)
    p = Discerner::Parameter.where(unique_identifier: 'consented').first
    expect(p).to_not be_blank
    expect(p.name).to eq 'Consented already'
    expect(p.parameter_category.name).to eq 'Another criteria'
  end

  it "parses parameter value categories from list" do
    parser = Discerner::Parser.new()
    expect(Discerner::ParameterValueCategory.order(:id).to_a).to be_empty
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Book criteria
            :parameters:
              - :name: "Genre"
                :unique_identifier: book_genre
                :search:
                  :model: Book
                  :method: Genre
                  :parameter_type: combobox
                  :parameter_value_categories:
                    - :name: Adventure
                      :unique_identifier: adventure
                      :collapse: true
                      :display_order: 1
                    - :name: Comic novel
                      :unique_identifier: comic
                    - :name: Historical
                      :unique_identifier: historical
                  :parameter_values:
                    - :search_value: "Robinsonade"
                      :parameter_value_category: adventure
    }
    parser.parse_dictionaries(dictionaries)
    expect(Discerner::ParameterValueCategory.order(:id).to_a.length).to eq 3
    expect(Discerner::ParameterValueCategory.where(unique_identifier: 'adventure')).to_not be_empty
    expect(Discerner::ParameterValueCategory.where(unique_identifier: 'adventure').first.collapse).to eq true
  end

  it "parses parameter value categories from source model and method" do
    parser = Discerner::Parser.new()
    expect(Discerner::ParameterValueCategory.order(:id).to_a).to be_empty
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Book criteria
            :parameters:
              - :name: "Genre"
                :unique_identifier: book_genre
                :search:
                  :model: Book
                  :method: Genre
                  :parameter_type: combobox
                  :parameter_value_categories_source:
                    :model: Book
                    :method: genres
                  :parameter_values:
                    - :search_value: "Robinsonade"
                      :parameter_value_category: adventure
    }
    parser.parse_dictionaries(dictionaries)
    expect(Discerner::ParameterValueCategory.order(:id).to_a.length).to eq 2
    expect(Discerner::ParameterValueCategory.where(unique_identifier: 'adventure')).to_not be_empty
    expect(Discerner::ParameterValueCategory.where(unique_identifier: 'adventure').first.collapse).to eq true
    expect(Discerner::ParameterValueCategory.where(unique_identifier: 'drama')).to_not be_empty
    expect(Discerner::ParameterValueCategory.where(unique_identifier: 'drama').first.collapse).to eq false
  end

  it "raisers an error message if parameter value category source model and method do not adhere to the interface" do
    parser = Discerner::Parser.new()
    expect(Discerner::ParameterValueCategory.order(:id).to_a).to be_empty
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Book criteria
            :parameters:
              - :name: "Genre"
                :unique_identifier: book_genre
                :search:
                  :model: Book
                  :method: Genre
                  :parameter_type: combobox
                  :parameter_value_categories_source:
                    :model: Book
                    :method: generes
                  :parameter_values:
                    - :search_value: "Robinsonade"
                      :parameter_value_category: adventure
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.errors).to eq [": method 'generes' does not adhere to the interface"]
    expect(Discerner::Dictionary.order(:id).to_a).to be_empty
  end

  it "assigns parameter values to corresponding parameter value categories" do
    parser = Discerner::Parser.new()
    expect(Discerner::ParameterValueCategory.order(:id).to_a).to be_empty
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Book criteria
            :parameters:
              - :name: "Genre"
                :unique_identifier: book_genre
                :search:
                  :model: Book
                  :method: Genre
                  :parameter_type: combobox
                  :parameter_value_categories:
                    - :name: Adventure
                      :unique_identifier: adventure
                  :parameter_values:
                    - :search_value: "Robinsonade"
                      :parameter_value_category: adventure
    }
    parser.parse_dictionaries(dictionaries)
    expect(Discerner::ParameterValueCategory.order(:id).to_a.length).to eq 1
    expect(Discerner::ParameterValueCategory.where(unique_identifier: 'adventure')).to_not be_empty
    expect(Discerner::ParameterValueCategory.where(unique_identifier: 'adventure').first.parameter_values.length).to eq 1
    expect(Discerner::ParameterValueCategory.where(unique_identifier: 'adventure').first.parameter_values.first.search_value).to eq 'Robinsonade'
  end

  ## cleanup on dictionaries

  it "does not delete dictionaries that are no longer defined in the definition file and are not used in searches if --prune_dictionaries parameter is not specified" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list

      - :name: Another dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_dictionaries.length).to eq 2
    expect(Discerner::Dictionary.order(:id).to_a).to_not be_empty
    expect(Discerner::Dictionary.where(name: 'Sample dictionary')).to_not be_blank
    expect(Discerner::Dictionary.where(name: 'Another dictionary')).to_not be_blank

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_dictionaries.length).to eq 1
    expect(Discerner::Dictionary.order(:id).to_a).to_not be_empty
    expect(Discerner::Dictionary.where(name: 'Sample dictionary')).to_not be_blank
    expect(Discerner::Dictionary.where(name: 'Another dictionary')).not_to be_blank
  end

  it "deletes dictionaries that are no longer defined in the definition file and are not used in searches --prune_dictionaries parameter is set" do
    parser = Discerner::Parser.new(prune_dictionaries: true)
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list

      - :name: Another dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_dictionaries.length).to eq 2
    expect(Discerner::Dictionary.order(:id).to_a).to_not be_empty
    expect(Discerner::Dictionary.where(name: 'Sample dictionary')).to_not be_blank
    expect(Discerner::Dictionary.where(name: 'Another dictionary')).to_not be_blank

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_dictionaries.length).to eq 1
    expect(Discerner::Dictionary.order(:id).to_a).to_not be_empty
    expect(Discerner::Dictionary.where(name: 'Sample dictionary')).to_not be_blank
    expect(Discerner::Dictionary.where(name: 'Another dictionary')).to be_blank
  end

  it "soft-deletes dictionaries that are no longer defined in the definition file but are used in searches and --prune_dictionaries option is specified" do
    parser = Discerner::Parser.new(prune_dictionaries:true)
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list

      - :name: Another dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_dictionaries.length).to eq 2
    expect(Discerner::Dictionary.where(name: 'Sample dictionary')).to_not be_blank
    expect(Discerner::Dictionary.where(name: 'Another dictionary')).to_not be_blank
    expect(Discerner::Dictionary.where(name: 'Another dictionary').first).to_not be_deleted

    dictionary = Discerner::Dictionary.where(name: "Another dictionary").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s)
    s.dictionary = dictionary
    s.save!

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_dictionaries.length).to eq 1
    expect(Discerner::Dictionary.order(:id).to_a).to_not be_empty
    expect(Discerner::Dictionary.where(name: 'Sample dictionary')).to_not be_blank
    expect(Discerner::Dictionary.where(name: 'Another dictionary')).to_not be_blank
    expect(Discerner::Dictionary.where(name: 'Another dictionary').first).to be_deleted
  end

  it "does not soft-delete dictionaries that are no longer defined in the definition file but are used in searches and --prune_dictionaries option is not specified" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list

      - :name: Another dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_dictionaries.length).to eq 2
    expect(Discerner::Dictionary.where(name: 'Sample dictionary')).to_not be_blank
    expect(Discerner::Dictionary.where(name: 'Another dictionary')).to_not be_blank
    expect(Discerner::Dictionary.where(name: 'Another dictionary').first).to_not be_deleted

    dictionary = Discerner::Dictionary.where(name: "Another dictionary").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s)
    s.dictionary = dictionary
    s.save!

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_dictionaries.length).to eq 1
    expect(Discerner::Dictionary.order(:id).to_a).to_not be_empty
    expect(Discerner::Dictionary.where(name: 'Sample dictionary')).to_not be_blank
    expect(Discerner::Dictionary.where(name: 'Another dictionary')).to_not be_blank
    expect(Discerner::Dictionary.where(name: 'Another dictionary').first).not_to be_deleted
  end

  ### cleanup on parameter categories

  it "deletes categories that are no longer defined in the definition file and are not used in searches" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list

          - :name: Patient criteria
            :parameters:
              - :name: Date of birth
                :unique_identifier: date_of_birth
                :search:
                  :model: Patient
                  :method: date_of_birth
                  :parameter_type: date
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_categories.length).to eq 2
    expect(Discerner::ParameterCategory.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterCategory.order(:id).to_a.length).to eq 2
    expect(Discerner::ParameterCategory.where(name: 'Demographic criteria')).to_not be_blank
    expect(Discerner::ParameterCategory.where(name: 'Patient criteria')).to_not be_blank

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_categories.length).to eq 1
    expect(Discerner::ParameterCategory.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterCategory.order(:id).to_a.length).to eq 1
    expect(Discerner::ParameterCategory.where(name: 'Demographic criteria')).to_not be_blank
    expect(Discerner::ParameterCategory.where(name: 'Patient criteria')).to be_blank
  end

  it "soft-deletes categories that are no longer defined in the definition file but are used in searches" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list

          - :name: Patient criteria
            :parameters:
              - :name: Date of birth
                :unique_identifier: date_of_birth
                :search:
                  :model: Patient
                  :method: date_of_birth
                  :parameter_type: date
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_categories.length).to eq 2
    expect(Discerner::ParameterCategory.order(:id).to_a.length).to eq 2
    expect(Discerner::ParameterCategory.where(name: 'Demographic criteria')).to_not be_blank
    expect(Discerner::ParameterCategory.where(name: 'Patient criteria')).to_not be_blank
    expect(Discerner::ParameterCategory.where(name: 'Patient criteria').first).to_not be_deleted

    category = Discerner::ParameterCategory.where(name: "Patient criteria").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: category.parameters.first)
    s.save!

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_categories.length).to eq 1
    expect(Discerner::ParameterCategory.order(:id).to_a.length).to eq 2
    expect(Discerner::ParameterCategory.where(name: 'Demographic criteria')).to_not be_blank
    expect(Discerner::ParameterCategory.where(name: 'Patient criteria')).to_not be_blank
    expect(Discerner::ParameterCategory.where(name: 'Patient criteria').first).to be_deleted
  end

  it "does not delete categories that belong to a dictionary that is no longer defined in the definition file if --prune_dictionaries parameter is not specified" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list

          - :name: Patient criteria
            :parameters:
              - :name: Date of birth
                :unique_identifier: date_of_birth
                :search:
                  :model: Patient
                  :method: date_of_birth
                  :parameter_type: date
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_categories.length).to eq 2
    expect(Discerner::ParameterCategory.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterCategory.order(:id).to_a.length).to eq 2
    expect(Discerner::ParameterCategory.where(name: 'Demographic criteria')).to_not be_blank
    expect(Discerner::ParameterCategory.where(name: 'Patient criteria')).to_not be_blank

    dictionaries = %Q{
    :dictionaries:
      - :name: Another Sample dictionary
        :parameter_categories:
          - :name: Another demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_categories.length).to eq 1
    expect(Discerner::ParameterCategory.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterCategory.order(:id).to_a.length).to eq 3
    expect(Discerner::ParameterCategory.where(name: 'Demographic criteria')).to_not be_blank
    expect(Discerner::ParameterCategory.where(name: 'Patient criteria')).not_to be_blank
  end

  it "soft-deletes categories that belong to a dictionary that is no longer defined in the definition file if --prune_dictionaries parameter is specified and category is used in searches" do
    parser = Discerner::Parser.new(prune_dictionaries: true)
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Patient criteria
            :parameters:
              - :name: Date of birth
                :unique_identifier: date_of_birth
                :search:
                  :model: Patient
                  :method: date_of_birth
                  :parameter_type: date
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_categories.length).to eq 1
    expect(Discerner::ParameterCategory.order(:id).to_a.length).to eq 1
    expect(Discerner::ParameterCategory.where(name: 'Patient criteria')).to_not be_blank
    expect(Discerner::ParameterCategory.where(name: 'Patient criteria').first).to_not be_deleted

    category = Discerner::ParameterCategory.where(name: "Patient criteria").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: category.parameters.first)
    s.save!

    dictionaries = %Q{
    :dictionaries:
      - :name: Another sample dictionary
        :parameter_categories:
          - :name: Another demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_categories.length).to eq 1
    expect(Discerner::ParameterCategory.order(:id).to_a.length).to eq 2
    expect(Discerner::ParameterCategory.where(name: 'Patient criteria')).to_not be_blank
    expect(Discerner::ParameterCategory.where(name: 'Patient criteria').first).to be_deleted
  end

  it "deletes categories that belong to a dictionary that is no longer defined in the definition file if --prune_dictionaries parameter is specified and  are not used in searches" do
    parser = Discerner::Parser.new(prune_dictionaries: true)
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_categories.length).to eq 1
    expect(Discerner::ParameterCategory.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterCategory.order(:id).to_a.length).to eq 1
    expect(Discerner::ParameterCategory.where(name: 'Demographic criteria')).to_not be_blank

    dictionaries = %Q{
    :dictionaries:
      - :name: Another sample dictionary
        :parameter_categories:
          - :name: Another demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_categories.length).to eq 1
    expect(Discerner::ParameterCategory.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterCategory.order(:id).to_a.length).to eq 1
    expect(Discerner::ParameterCategory.where(name: 'Demographic criteria')).to be_blank
  end

  ### cleanup on parameters

  it "deletes parameters that are no longer defined in the definition file and are not used in searches" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list

              - :name: Gender
                :unique_identifier: gender
                :search:
                  :model: Patient
                  :method: gender
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameters.length).to eq 2
    expect(Discerner::Parameter.order(:id).to_a).to_not be_empty
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 2
    expect(Discerner::Parameter.where(unique_identifier: 'ethnic_grp')).to_not be_blank
    expect(Discerner::Parameter.where(unique_identifier: 'gender')).to_not be_blank

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameters.length).to eq 1
    expect(Discerner::Parameter.order(:id).to_a).to_not be_empty
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 1
    expect(Discerner::Parameter.where(unique_identifier: 'ethnic_grp')).to_not be_blank
    expect(Discerner::Parameter.where(unique_identifier: 'gender')).to be_blank
  end

  it "soft-deletes parameters that are no longer defined in the definition file but are used in searches" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list

              - :name: Gender
                :unique_identifier: gender
                :search:
                  :model: Patient
                  :method: gender
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameters.length).to eq 2
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 2
    expect(Discerner::Parameter.where(unique_identifier: 'ethnic_grp')).to_not be_blank
    expect(Discerner::Parameter.where(unique_identifier: 'gender')).to_not be_blank
    expect(Discerner::Parameter.where(unique_identifier: 'gender').first).to_not be_deleted

    parameter = Discerner::Parameter.where(unique_identifier: "gender").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: parameter)
    s.save!

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameters.length).to eq 1
    expect(Discerner::Parameter.order(:id).to_a).to_not be_empty
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 2
    expect(Discerner::Parameter.where(unique_identifier: 'ethnic_grp')).to_not be_blank
    expect(Discerner::Parameter.where(unique_identifier: 'gender')).to_not be_blank
    expect(Discerner::Parameter.where(unique_identifier: 'gender').first).to be_deleted
  end

  it "does not delete parameters that belong to a dictionary that is no longer defined in the definition file if --prune_dictionaries parameter is not specified" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameters.length).to eq 1
    expect(Discerner::Parameter.order(:id).to_a).to_not be_empty
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 1
    expect(Discerner::Parameter.where(unique_identifier: 'ethnic_grp')).to_not be_blank

    dictionaries = %Q{
    :dictionaries:
      - :name: Another ample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: another_ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameters.length).to eq 1
    expect(Discerner::Parameter.order(:id).to_a).to_not be_empty
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 2
    expect(Discerner::Parameter.where(unique_identifier: 'ethnic_grp')).to_not be_blank
  end

  it "deletes parameters that belong to a dictionary that is no longer defined in the definition file if --prune_dictionaries parameter is specified" do
    parser = Discerner::Parser.new(prune_dictionaries:true)
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameters.length).to eq 1
    expect(Discerner::Parameter.order(:id).to_a).to_not be_empty
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 1
    expect(Discerner::Parameter.where(unique_identifier: 'ethnic_grp')).to_not be_blank

    dictionaries = %Q{
    :dictionaries:
      - :name: Another ample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: another_ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameters.length).to eq 1
    expect(Discerner::Parameter.order(:id).to_a).to_not be_empty
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 1
    expect(Discerner::Parameter.where(unique_identifier: 'ethnic_grp')).to be_blank
  end

  it "soft-deletes parameters that are used in searches but belong to a dictionary that is no longer defined in the definition file when --prune_dictionaries parameter is specified" do
    parser = Discerner::Parser.new(prune_dictionaries: true)
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Gender
                :unique_identifier: gender
                :search:
                  :model: Patient
                  :method: gender
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameters.length).to eq 1
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 1
    expect(Discerner::Parameter.where(unique_identifier: 'gender')).to_not be_blank
    expect(Discerner::Parameter.where(unique_identifier: 'gender').first).to_not be_deleted

    parameter = Discerner::Parameter.where(unique_identifier: "gender").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: parameter)
    s.save!

    dictionaries = %Q{
    :dictionaries:
      - :name: Another sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameters.length).to eq 1
    expect(Discerner::Parameter.order(:id).to_a).to_not be_empty
    expect(Discerner::Parameter.order(:id).to_a.length).to eq 2
    expect(Discerner::Parameter.where(unique_identifier: 'ethnic_grp')).to_not be_blank
    expect(Discerner::Parameter.where(unique_identifier: 'gender')).to_not be_blank
    expect(Discerner::Parameter.where(unique_identifier: 'gender').first).to be_deleted
  end

  ### cleanup on parameter values

  it "deletes parameter values that are no longer defined in the definition file and are not used in searches" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 3 # 2 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 2 # 1 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank
  end

  it "does not delete parameter values that belong to a dictionary that is no longer defined in the definition file if --prune_dictionaries parameter is not specified" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 3 # 2 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank

    dictionaries = %Q{
    :dictionaries:
      - :name: Another sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: another_ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: German
                      :search_value: german
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 2 # 1 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).not_to be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank
  end

  it "deletes parameter values that are not used in searches and belong to a dictionary that is no longer defined in the definition file if --prune_dictionaries parameter is specified" do
    parser = Discerner::Parser.new(prune_dictionaries:true)
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 2 # 1 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank

    dictionaries = %Q{
    :dictionaries:
      - :name: Another sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: another_ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: German
                      :search_value: german
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 2 # 1 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank
  end

  it "deletes parameter values that are no longer defined in the definition file and used in list searches as not chosen options" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
                    - :name: Unable to answer
                      :search_value: unknown
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 4 # 3 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank

    value = Discerner::ParameterValue.where(search_value: "unknown").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: value.parameter)
    s.save!
    FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first, parameter_value: value)

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 3 # 2 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown')).to be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank
  end

  it "does not deletes parameter values that are used in list searches as not chosen options and belong to a dictionary that is no longer defined in the definition file if --prune_dictionaries parameter is not specified" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
                    - :name: Unable to answer
                      :search_value: unknown
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 4 # 3 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank

    value = Discerner::ParameterValue.where(search_value: "unknown").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: value.parameter)
    s.save!
    FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first, parameter_value: value)

    dictionaries = %Q{
    :dictionaries:
      - :name: Anoher sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: another_ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: German
                      :search_value: german
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 2 # 1 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown')).not_to be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank
  end

  it "deletes parameter values that are used in list searches as not chosen options and belong to a dictionary that is no longer defined in the definition file if --prune_dictionaries parameter is specified" do
    parser = Discerner::Parser.new(prune_dictionaries: true)
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
                    - :name: Unable to answer
                      :search_value: unknown
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 4 # 3 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank

    value = Discerner::ParameterValue.where(search_value: "unknown").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: value.parameter)
    s.save!
    FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first, parameter_value: value)

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: German
                      :search_value: german
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 2 # 1 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown')).to be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank
  end

  it "soft-deletes parameter values that are no longer defined in the definition file but are used in searches" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
                    - :name: Unable to answer
                      :search_value: unknown
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 4 # 3 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.order(:id).to_a.length).to eq 4
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown').first).to_not be_deleted
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank

    value = Discerner::ParameterValue.where(search_value: "unknown").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: value.parameter)
    s.save!
    FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first, parameter_value: value, chosen: true)
    FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first, parameter_value: value, operator: Discerner::Operator.last)

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 3 # 2 + 1 blank
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.order(:id).to_a.length).to eq 4
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown').first).to be_deleted
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank
  end

  it "does not soft-deletes parameter values that are used in searches and belong to a dictionary that is no longer defined in the definition file if --prune_dictionaries parameter is not specified" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
                    - :name: Unable to answer
                      :search_value: unknown
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 4 # 3 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.order(:id).to_a.length).to eq 4
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown').first).to_not be_deleted
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank

    value = Discerner::ParameterValue.where(search_value: "unknown").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: value.parameter)
    s.save!
    FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first, parameter_value: value, chosen: true)
    FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first, parameter_value: value, operator: Discerner::Operator.last)

    dictionaries = %Q{
    :dictionaries:
      - :name: Another sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: German
                      :search_value: german
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 2 # 1 + 1 blank
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.order(:id).to_a.length).to eq 6
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino').first).to_not be_deleted
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino').first).to_not be_deleted
    expect(Discerner::ParameterValue.where(search_value: 'unknown').first).to_not be_deleted
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank
  end

  it "soft-deletes parameter values that are used in searches and belong to a dictionary that is no longer defined in the definition file if --prune_dictionaries parameter is specified" do
    parser = Discerner::Parser.new(prune_dictionaries:true)
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Unable to answer
                      :search_value: unknown
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 2 # 1 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.order(:id).to_a.length).to eq 2
    expect(Discerner::ParameterValue.where(search_value: 'unknown')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown').first).to_not be_deleted
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank

    value = Discerner::ParameterValue.where(search_value: "unknown").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: value.parameter)
    s.save!
    FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first, parameter_value: value, chosen: true)
    FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first, parameter_value: value, operator: Discerner::Operator.last)

    dictionaries = %Q{
    :dictionaries:
      - :name: Another sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: German
                      :search_value: german
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 2 # 1 + 1 blank
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.order(:id).to_a.length).to eq 3 # blank value from the frst set should be deleted
    expect(Discerner::ParameterValue.where(search_value: 'unknown')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'unknown').first).to be_deleted
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank
  end

  it "creates options with newly added values for search parameters linked with updated parameter" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 2 # 1 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank

    value = Discerner::ParameterValue.where(search_value: "not_hisp_or_latino").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: value.parameter)
    s.save!
    FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first, parameter_value: value)

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
                    - :name: Unable to answer
                      :search_value: unknown
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 4 # 3 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino')).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: '')).to_not be_blank

    expect(Discerner::ParameterValue.where(search_value: 'hisp_or_latino').first.search_parameter_values).to_not be_blank
    expect(Discerner::ParameterValue.where(search_value: 'not_hisp_or_latino').first.search_parameter_values).to_not be_blank
  end

  it "creates options with un-deleted values for search parameters linked with updated parameter" do
    parser = Discerner::Parser.new()
    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 3 # 2 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.order(:id).to_a.length).to eq 3

    value = Discerner::ParameterValue.where(search_value: "hisp_or_latino").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s, parameter: value.parameter)
    s.save!
    FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first, parameter_value: value, chosen: true)


    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 2 # 1 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.order(:id).to_a.length).to eq 3
    expect(Discerner::ParameterValue.not_deleted.order(:id).to_a.length).to eq 2
    expect(Discerner::SearchParameterValue.order(:id).to_a.length).to eq 1 #parameter value is not added or deleted, so no thanges

    dictionaries = %Q{
    :dictionaries:
      - :name: Sample dictionary
        :parameter_categories:
          - :name: Demographic criteria
            :parameters:
              - :name: Ethnic group
                :unique_identifier: ethnic_grp
                :search:
                  :model: Patient
                  :method: ethnic_grp
                  :parameter_type: list
                  :parameter_values:
                    - :name: Hispanic or Latino
                      :search_value: hisp_or_latino
                    - :name: NOT Hispanic or Latino
                      :search_value: not_hisp_or_latino
    }
    parser.parse_dictionaries(dictionaries)
    expect(parser.updated_parameter_values.length).to eq 3 # 2 + 1 blank
    expect(parser.blank_parameter_values.length).to eq 1
    expect(Discerner::ParameterValue.order(:id).to_a).to_not be_empty
    expect(Discerner::ParameterValue.order(:id).to_a.length).to eq 3
    expect(Discerner::ParameterValue.not_deleted.order(:id).to_a.length).to eq 3
    expect(Discerner::SearchParameterValue.order(:id).to_a.length).to eq 1 #parameter value is not added or deleted, so no thanges
  end
end