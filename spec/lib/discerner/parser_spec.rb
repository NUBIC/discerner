require 'spec_helper'

describe Discerner::Parser do
  it "parses operators" do
    file = 'lib/setup/operators.yml'
    parser = Discerner::Parser.new()
    parser.parse_operators(File.read(file))

    Discerner::Operator.order(:id).to_a.should_not be_empty
    Discerner::ParameterType.order(:id).to_a.should_not be_empty
  end

  it "parses dictionaries" do
    file = 'test/dummy/lib/setup/dictionaries.yml'
    parser = Discerner::Parser.new()
    parser.parse_dictionaries(File.read(file))

    Discerner::Dictionary.order(:id).to_a.should_not be_empty
    Discerner::Dictionary.order(:id).to_a.length.should == 2

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

    dictionary.parameter_categories.first.parameters.where(:unique_identifier => 'ethnic_grp').first. should have(5).parameter_values # extra 'None' value added
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

    Discerner::Dictionary.order(:id).to_a.should_not be_empty
    Discerner::Dictionary.order(:id).to_a.length.should == 1
    Discerner::Parameter.order(:id).to_a.length.should == 1
    p = Discerner::Parameter.last
    p.name.should == 'Ethnic group'

    ethnic_groups_names = Patient.ethnic_groups.map { |ethnic_group| ethnic_group[:name] }
    ethnic_groups_search_values = Patient.ethnic_groups.map { |ethnic_group| ethnic_group[:search_value] }
    Set.new(p.parameter_values.map(&:name)).should == Set.new(ethnic_groups_names + ['None'])
    Set.new(p.parameter_values.map(&:search_value)).should == Set.new(ethnic_groups_search_values + [''])
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
                  :parameter_type: list
                  :source:
                    :model: Patient
                    :method: smethnic_groups
    }
    parser.parse_dictionaries(dictionaries)
    parser.errors.should == [": method 'smethnic_groups' does not adhere to the interface"]
    Discerner::Dictionary.order(:id).to_a.should be_empty
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
    Discerner::Dictionary.order(:id).to_a.should_not be_empty
    Discerner::Dictionary.order(:id).to_a.length.should == 1
    Discerner::Parameter.order(:id).to_a.length.should == 1
    p = Discerner::Parameter.last
    p.name.should == 'Gender'

    genders = Patient.order(:id).to_a.map { |patient| patient.gender }
    Set.new(p.parameter_values.map(&:name)).should == Set.new(genders + ['None'])
    Set.new(p.parameter_values.map(&:search_value)).should == Set.new(genders + [''])
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
      d.should_not be_deleted
    end
    Discerner::Dictionary.order(:id).to_a.length.should == count
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
      d.should_not be_deleted
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
      d.should_not be_deleted
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
    Discerner::Parameter.order(:id).to_a.length.should == 1
    Discerner::Parameter.last.parameter_values.each do |pv|
      ['true', 'false', 'None'].should include(pv.name)
    end
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
    p = Discerner::Parameter.where(:unique_identifier => 'consented').first
    p.should_not be_blank
    p.name.should == 'Consented'
    p.parameter_category.name.should == 'Demographic criteria'

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
    p = Discerner::Parameter.where(:unique_identifier => 'consented').first
    p.should_not be_blank
    p.name.should == 'Consented already'
    p.parameter_category.name.should == 'Another criteria'
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
    Discerner::Dictionary.order(:id).to_a.should_not be_empty
    Discerner::Dictionary.where(:name => 'Sample dictionary').should_not be_blank
    Discerner::Dictionary.where(:name => 'Another dictionary').should_not be_blank

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
    Discerner::Dictionary.order(:id).to_a.should_not be_empty
    Discerner::Dictionary.where(:name => 'Sample dictionary').should_not be_blank
    Discerner::Dictionary.where(:name => 'Another dictionary').should be_blank
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
                  :parameter_type: date
    }
    parser.parse_dictionaries(dictionaries)
    parser.updated_categories.length.should == 2
    Discerner::ParameterCategory.order(:id).to_a.should_not be_empty
    Discerner::ParameterCategory.order(:id).to_a.length.should == 2
    Discerner::ParameterCategory.where(:name => 'Demographic criteria').should_not be_blank
    Discerner::ParameterCategory.where(:name => 'Patient criteria').should_not be_blank

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
    Discerner::ParameterCategory.order(:id).to_a.should_not be_empty
    Discerner::ParameterCategory.order(:id).to_a.length.should == 1
    Discerner::ParameterCategory.where(:name => 'Demographic criteria').should_not be_blank
    Discerner::ParameterCategory.where(:name => 'Patient criteria').should be_blank
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
    Discerner::Parameter.order(:id).to_a.should_not be_empty
    Discerner::Parameter.order(:id).to_a.length.should == 2
    Discerner::Parameter.where(:unique_identifier => 'ethnic_grp').should_not be_blank
    Discerner::Parameter.where(:unique_identifier => 'gender').should_not be_blank

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
    Discerner::Parameter.order(:id).to_a.should_not be_empty
    Discerner::Parameter.order(:id).to_a.length.should == 1
    Discerner::Parameter.where(:unique_identifier => 'ethnic_grp').should_not be_blank
    Discerner::Parameter.where(:unique_identifier => 'gender').should be_blank
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
    }
    parser.parse_dictionaries(dictionaries)
    parser.updated_parameter_values.length.should == 2
    parser.blank_parameter_values.length.should == 1
    Discerner::ParameterValue.order(:id).to_a.should_not be_empty
    Discerner::ParameterValue.where(:search_value => 'hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'not_hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => '').should_not be_blank

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
    parser.updated_parameter_values.length.should == 1
    parser.blank_parameter_values.length.should == 1
    Discerner::ParameterValue.where(:search_value => 'hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'not_hisp_or_latino').should be_blank
    Discerner::ParameterValue.where(:search_value => '').should_not be_blank
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
    parser.updated_parameter_values.length.should == 3
    parser.blank_parameter_values.length.should == 1
    Discerner::ParameterValue.where(:search_value => 'hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'not_hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'unknown').should_not be_blank
    Discerner::ParameterValue.where(:search_value => '').should_not be_blank

    value = Discerner::ParameterValue.where(:search_value => "unknown").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => value.parameter)
    s.save!
    FactoryGirl.create(:search_parameter_value, :search_parameter => s.search_parameters.first, :parameter_value => value)

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
    parser.blank_parameter_values.length.should == 1
    Discerner::ParameterValue.order(:id).to_a.should_not be_empty
    Discerner::ParameterValue.where(:search_value => 'hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'not_hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'unknown').should be_blank
    Discerner::ParameterValue.where(:search_value => '').should_not be_blank
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
    Discerner::Dictionary.where(:name => 'Sample dictionary').should_not be_blank
    Discerner::Dictionary.where(:name => 'Another dictionary').should_not be_blank
    Discerner::Dictionary.where(:name => 'Another dictionary').first.should_not be_deleted

    dictionary = Discerner::Dictionary.where(:name => "Another dictionary").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s)
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
    Discerner::Dictionary.order(:id).to_a.should_not be_empty
    Discerner::Dictionary.where(:name => 'Sample dictionary').should_not be_blank
    Discerner::Dictionary.where(:name => 'Another dictionary').should_not be_blank
    Discerner::Dictionary.where(:name => 'Another dictionary').first.should be_deleted
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
    parser.updated_categories.length.should == 2
    Discerner::ParameterCategory.order(:id).to_a.length.should == 2
    Discerner::ParameterCategory.where(:name => 'Demographic criteria').should_not be_blank
    Discerner::ParameterCategory.where(:name => 'Patient criteria').should_not be_blank
    Discerner::ParameterCategory.where(:name => 'Patient criteria').first.should_not be_deleted

    category = Discerner::ParameterCategory.where(:name => "Patient criteria").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => category.parameters.first)
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
    Discerner::ParameterCategory.order(:id).to_a.length.should == 2
    Discerner::ParameterCategory.where(:name => 'Demographic criteria').should_not be_blank
    Discerner::ParameterCategory.where(:name => 'Patient criteria').should_not be_blank
    Discerner::ParameterCategory.where(:name => 'Patient criteria').first.should be_deleted
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
    Discerner::Parameter.order(:id).to_a.length.should == 2
    Discerner::Parameter.where(:unique_identifier => 'ethnic_grp').should_not be_blank
    Discerner::Parameter.where(:unique_identifier => 'gender').should_not be_blank
    Discerner::Parameter.where(:unique_identifier => 'gender').first.should_not be_deleted

    parameter = Discerner::Parameter.where(:unique_identifier => "gender").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => parameter)
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
    Discerner::Parameter.order(:id).to_a.should_not be_empty
    Discerner::Parameter.order(:id).to_a.length.should == 2
    Discerner::Parameter.where(:unique_identifier => 'ethnic_grp').should_not be_blank
    Discerner::Parameter.where(:unique_identifier => 'gender').should_not be_blank
    Discerner::Parameter.where(:unique_identifier => 'gender').first.should be_deleted
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
    parser.blank_parameter_values.length.should == 1
    Discerner::ParameterValue.order(:id).to_a.should_not be_empty
    Discerner::ParameterValue.order(:id).to_a.length.should == 4
    Discerner::ParameterValue.where(:search_value => 'hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'not_hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'unknown').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'unknown').first.should_not be_deleted
    Discerner::ParameterValue.where(:search_value => '').should_not be_blank

    value = Discerner::ParameterValue.where(:search_value => "unknown").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => value.parameter)
    s.save!
    FactoryGirl.create(:search_parameter_value, :search_parameter => s.search_parameters.first, :parameter_value => value, :chosen => true)
    FactoryGirl.create(:search_parameter_value, :search_parameter => s.search_parameters.first, :parameter_value => value, :operator => Discerner::Operator.last)

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
    Discerner::ParameterValue.order(:id).to_a.should_not be_empty
    Discerner::ParameterValue.order(:id).to_a.length.should == 4
    Discerner::ParameterValue.where(:search_value => 'hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'not_hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'unknown').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'unknown').first.should be_deleted
    Discerner::ParameterValue.where(:search_value => '').should_not be_blank
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
    parser.updated_parameter_values.length.should == 1
    parser.blank_parameter_values.length.should == 1
    Discerner::ParameterValue.order(:id).to_a.should_not be_empty
    Discerner::ParameterValue.where(:search_value => 'not_hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => '').should_not be_blank

    value = Discerner::ParameterValue.where(:search_value => "not_hisp_or_latino").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => value.parameter)
    s.save!
    FactoryGirl.create(:search_parameter_value, :search_parameter => s.search_parameters.first, :parameter_value => value)

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
    parser.blank_parameter_values.length.should == 1
    Discerner::ParameterValue.order(:id).to_a.should_not be_empty
    Discerner::ParameterValue.where(:search_value => 'hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'not_hisp_or_latino').should_not be_blank
    Discerner::ParameterValue.where(:search_value => '').should_not be_blank

    Discerner::ParameterValue.where(:search_value => 'hisp_or_latino').first.search_parameter_values.should_not be_blank
    Discerner::ParameterValue.where(:search_value => 'not_hisp_or_latino').first.search_parameter_values.should_not be_blank
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
    parser.updated_parameter_values.length.should == 2
    parser.blank_parameter_values.length.should == 1
    Discerner::ParameterValue.order(:id).to_a.should_not be_empty
    Discerner::ParameterValue.order(:id).to_a.length.should == 3

    value = Discerner::ParameterValue.where(:search_value => "hisp_or_latino").first
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, :search => s, :parameter => value.parameter)
    s.save!
    FactoryGirl.create(:search_parameter_value, :search_parameter => s.search_parameters.first, :parameter_value => value, :chosen => true)


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
    parser.updated_parameter_values.length.should == 1
    parser.blank_parameter_values.length.should == 1
    Discerner::ParameterValue.order(:id).to_a.should_not be_empty
    Discerner::ParameterValue.order(:id).to_a.length.should == 3
    Discerner::ParameterValue.not_deleted.order(:id).to_a.length.should == 2
    Discerner::SearchParameterValue.order(:id).to_a.length.should == 1 #parameter value is not added or deleted, so no thanges

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
    parser.blank_parameter_values.length.should == 1
    Discerner::ParameterValue.order(:id).to_a.should_not be_empty
    Discerner::ParameterValue.order(:id).to_a.length.should == 3
    Discerner::ParameterValue.not_deleted.order(:id).to_a.length.should == 3
    Discerner::SearchParameterValue.order(:id).to_a.length.should == 1 #parameter value is not added or deleted, so no thanges
  end
end