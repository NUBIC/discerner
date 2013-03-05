require 'spec_helper'

describe Discerner::Parser do
  it "parses operators" do
    file = 'lib/setup/operators.yml'
    parser = Discerner::Parser.new()
    parser.parse_operators(File.read(file))

    Discerner::Operator.all.should_not be_empty
    Discerner::Operator.where(:text => 'is not like').should_not be_empty
    Discerner::ParameterType.all.should_not be_empty
  end

  it "parses dictionaries" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new(:trace => true)
    parser.parse_dictionaries(File.read(file))

    Discerner::Dictionary.all.should_not be_empty
    Discerner::Dictionary.all.length.should == 3

    dictionary = Discerner::Dictionary.find_by_name('Sample dictionary')
    dictionary.should_not be_blank
    dictionary.should have(2).parameter_categories
    dictionary.should have(2).searchable_categories
    dictionary.should have(1).exportable_categories
    dictionary.should_not be_deleted

    dictionary.parameter_categories.first.should have(7).parameters
    dictionary.parameter_categories.first.should have(6).searchable_parameters
    dictionary.parameter_categories.first.should have(4).exportable_parameters
    dictionary.parameter_categories.first.should_not be_deleted

    dictionary.parameter_categories.last.should have(2).parameters
    dictionary.parameter_categories.last.should_not be_deleted

    Discerner::Parameter.all.count.should == 16

    dictionary = Discerner::Dictionary.find_by_name('Deleted dictionary')
    dictionary.should be_deleted
    dictionary.should have(1).parameter_categories
    dictionary.parameter_categories.first.should be_deleted

    dictionary.parameter_categories.first.should have(1).parameters
    dictionary.parameter_categories.first.parameters.first.should be_deleted

    Discerner::ParameterValue.all.length.should == 24
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
              :parameter_type: numeric
              :source:
                :model: Patient
                :method: ethnic_groups
}
    parser.parse_dictionaries(dictionaries)

    Discerner::Dictionary.all.should_not be_empty
    Discerner::Dictionary.all.length.should == 1
    Discerner::Parameter.all.length.should == 1
    p = Discerner::Parameter.last
    p.name.should == 'Ethnic group'
    p.parameter_values.length.should == 2

    ethnic_groups_names = Patient.ethnic_groups.map { |ethnic_group| ethnic_group[:name] }
    ethnic_groups_search_values = Patient.ethnic_groups.map { |ethnic_group| ethnic_group[:search_value] }
    Set.new(p.parameter_values.map(&:name)).should == Set.new(ethnic_groups_names)
    Set.new(p.parameter_values.map(&:search_value)).should == Set.new(ethnic_groups_search_values)
  end


  it "raisers an error message with a source model and method that does not conform to the :name, :search_value interface" do
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
              :parameter_type: numeric
              :source:
                :model: Patient
                :method: smethnic_groups
}

    parser.parse_dictionaries(dictionaries)
    parser.errors.should == [": method 'smethnic_groups' does not adhere to the interface"]
    Discerner::Dictionary.all.should be_empty
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
          :unique_identifier: ethnic_grp
          :search:
            :model: Patient
            :method: gender
            :parameter_type: numeric
            :source:
              :model: Patient
              :method: gender
              :parameter_type: list
}
    parser.parse_dictionaries(dictionaries)
    Discerner::Dictionary.all.should_not be_empty
    Discerner::Dictionary.all.length.should == 1
    Discerner::Parameter.all.length.should == 1
    p = Discerner::Parameter.last
    p.name.should == 'Gender'
    p.parameter_values.length.should == 2

    genders = Patient.all.map { |patient| patient.gender }

    Set.new(p.parameter_values.map(&:name)).should == Set.new(genders)
    Set.new(p.parameter_values.map(&:search_value)).should == Set.new(genders)
  end


  it "restores soft deleted dictionaries if they are not marked as deleted in the dictionary definition" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new()
    parser.parse_dictionaries(File.read(file))

    Discerner::Dictionary.all.each do |d|
      d.deleted_at = Time.now
      d.save
    end

    parser.parse_dictionaries(File.read(file))
    Discerner::Dictionary.find_by_name('Sample dictionary').should_not be_blank
    Discerner::Dictionary.find_by_name('Sample dictionary').should_not be_deleted
    Discerner::Dictionary.find_by_name('Deleted dictionary').should_not be_blank
    Discerner::Dictionary.find_by_name('Deleted dictionary').should be_deleted
  end

  it "restores soft deleted parameter categories if they are not marked as deleted in the dictionary definition" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new()
    parser.parse_dictionaries(File.read(file))

    Discerner::ParameterCategory.all.each do |d|
      d.deleted_at = Time.now
      d.save
    end

    parser.parse_dictionaries(File.read(file))
    Discerner::ParameterCategory.all.each do |d|
      if d.name == 'Deleted category A'
        d.should be_deleted
      else
        d.should_not be_deleted
      end
    end
  end


  it "restores soft deleted parameters if they are not marked as deleted in the dictionary definition" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new()
    parser.parse_dictionaries(File.read(file))

    Discerner::Parameter.all.each do |d|
      d.deleted_at = Time.now
      d.save
    end

    parser.parse_dictionaries(File.read(file))
    Discerner::Parameter.all.each do |d|
      if d.name == 'Deleted date parameter'
        d.should be_deleted
      else
        d.should_not be_deleted
      end
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
    Discerner::Parameter.all.length.should == 1
    Discerner::Parameter.last.parameter_values.length.should == 2
    Discerner::Parameter.last.parameter_values.each do |pv|
      ['true', 'false'].should include(pv.name)
    end
  end

  it "finds and updates moved parameter" do
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
    Discerner::Parameter.all.length.should == 1
    Discerner::Parameter.last.name.should == 'Consented'

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
  Discerner::Parameter.all.length.should == 1
  Discerner::Parameter.last.name.should == 'Consented already'
  end

  it "deletes dictionaries that are no longer defined in the definition file and are not used in searches" do
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
    parser.updated_dictionaries.length.should == 2
    Discerner::Dictionary.all.should_not be_empty
    Discerner::Dictionary.all.length.should == 2
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
    parser.updated_dictionaries.length.should == 1
    Discerner::Dictionary.all.should_not be_empty
    Discerner::Dictionary.all.length.should == 1
    Discerner::Dictionary.not_deleted.all.length.should == 1
  end

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
              :parameter_type: list
}
    parser.parse_dictionaries(dictionaries)
    parser.updated_categories.length.should == 2
    Discerner::ParameterCategory.all.should_not be_empty
    Discerner::ParameterCategory.all.length.should == 2

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
    parser.updated_categories.length.should == 1
    Discerner::ParameterCategory.all.should_not be_empty
    Discerner::ParameterCategory.all.length.should == 1
    Discerner::ParameterCategory.not_deleted.all.length.should == 1
  end

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
    parser.updated_parameters.length.should == 2
    Discerner::Parameter.all.should_not be_empty
    Discerner::Parameter.all.length.should == 2
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
    parser.updated_parameters.length.should == 1
    Discerner::Parameter.all.should_not be_empty
    Discerner::Parameter.all.length.should == 1
    Discerner::Parameter.not_deleted.all.length.should == 1
  end

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
                - :name: Unable to answer
                  :search_value: unknown
                - :name: Declined to answer
                  :search_value: declined
}
    parser.parse_dictionaries(dictionaries)
    parser.updated_parameter_values.length.should == 4
    Discerner::ParameterValue.all.should_not be_empty
    Discerner::ParameterValue.all.length.should == 4
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
    parser.updated_parameter_values.length.should == 2
    Discerner::ParameterValue.all.should_not be_empty
    Discerner::ParameterValue.all.length.should == 2
    Discerner::ParameterValue.not_deleted.all.length.should == 2
  end

  it "soft-deletes dictionaries that are no longer defined in the definition file but are used in searches" do
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
    parser.updated_dictionaries.length.should == 2
    Discerner::Dictionary.all.should_not be_empty
    Discerner::Dictionary.all.length.should == 2

    dictionary = Discerner::Dictionary.where(:name => "Another dictionary").first
    s = Factory.build(:search)
    s.search_parameters << Factory.build(:search_parameter, :search => s)
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
    parser.updated_dictionaries.length.should == 1
    Discerner::Dictionary.all.should_not be_empty
    Discerner::Dictionary.all.length.should == 2
    Discerner::Dictionary.not_deleted.all.length.should == 1
    dictionary.reload.should be_deleted
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
              :parameter_type: list
}
    parser.parse_dictionaries(dictionaries)
    parser.updated_categories.length.should == 2
    Discerner::ParameterCategory.all.should_not be_empty
    Discerner::ParameterCategory.all.length.should == 2

    category = Discerner::ParameterCategory.where(:name => "Patient criteria").first
    s = Factory.build(:search)
    s.search_parameters << Factory.build(:search_parameter, :search => s, :parameter => category.parameters.first)
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
    parser.updated_categories.length.should == 1
    Discerner::ParameterCategory.all.should_not be_empty
    Discerner::ParameterCategory.all.length.should == 2
    Discerner::ParameterCategory.not_deleted.all.length.should == 1
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
    parser.updated_parameters.length.should == 2
    Discerner::Parameter.all.should_not be_empty
    Discerner::Parameter.all.length.should == 2

    parameter = Discerner::Parameter.where(:unique_identifier => "gender").first
    s = Factory.build(:search)
    s.search_parameters << Factory.build(:search_parameter, :search => s, :parameter => parameter)
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
    parser.updated_parameters.length.should == 1
    Discerner::Parameter.all.should_not be_empty
    Discerner::Parameter.all.length.should == 2
    Discerner::Parameter.not_deleted.all.length.should == 1
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
    parser.updated_parameter_values.length.should == 3
    Discerner::ParameterValue.all.should_not be_empty
    Discerner::ParameterValue.all.length.should == 3

    value = Discerner::ParameterValue.where(:search_value => "unknown").first
    s = Factory.build(:search)
    s.search_parameters << Factory.build(:search_parameter, :search => s, :parameter => value.parameter)
    s.save!
    Factory.create(:search_parameter_value, :search_parameter => s.search_parameters.first, :parameter_value => value)

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
    parser.updated_parameter_values.length.should == 2
    Discerner::ParameterValue.all.should_not be_empty
    Discerner::ParameterValue.all.length.should == 3
    Discerner::ParameterValue.not_deleted.all.length.should == 2
  end
end