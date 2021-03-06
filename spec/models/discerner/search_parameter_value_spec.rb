require 'spec_helper'

describe Discerner::SearchParameterValue do
  let(:search_parameter_value) {
    s = FactoryGirl.build(:search)
    search_parameter = FactoryGirl.build(:search_parameter, search: s)
    p = search_parameter.parameter
    p.search_method = 'age'
    p.search_model = 'Person'
    p.save!
    s.search_parameters << search_parameter
    s.dictionary = Discerner::Dictionary.last
    s.save!
    FactoryGirl.create(:search_parameter_value, search_parameter: s.search_parameters.first)
  }

  it "is valid with valid attributes" do
    expect(search_parameter_value).to be_valid
  end

  it "allows to access matching search criteria" do
    expect(search_parameter_value).to respond_to :search_parameter
  end

  it "should throw error if 'to_sql' method is called and operator is not defined" do
    search_parameter_value.operator = nil
    expect{search_parameter_value.to_sql}.to raise_error(RuntimeError, /Search operator has to be defined/)
  end

  it "allows to generate sql for search values with 'comparison' operators" do
    search_parameter_value.value = '50'
    search_parameter_value.operator = Discerner::Operator.find_by_symbol('>') || FactoryGirl.create(:operator, symbol: '>', text: 'is greater', operator_type: 'comparison')
    expect(search_parameter_value.to_sql).to_not be_empty
    expect(search_parameter_value.to_sql[:predicates]).to eq "age > ?"
    expect(search_parameter_value.to_sql[:values]).to eq '50'
  end

  it "allows to generate sql for search values with 'range' operator" do
    search_parameter_value.value = '40'
    search_parameter_value.additional_value = '50'
    search_parameter_value.operator = Discerner::Operator.find_by_symbol('between') || FactoryGirl.create(:operator, symbol: 'between', text: 'is in the range', operator_type: 'range')
    expect(search_parameter_value.to_sql).to_not be_empty
    expect(search_parameter_value.to_sql[:predicates]).to eq "age between ? and ?"
    expect(search_parameter_value.to_sql[:values]).to eq ["40", "50"]
  end

  it "allows to generate sql for search values with 'text_comparison' operators" do
    search_parameter_value.value = '50'
    search_parameter_value.operator = Discerner::Operator.find_by_symbol('is not like') || FactoryGirl.create(:operator, symbol: 'is not like', text: 'is not like', operator_type: 'text_comparison')
    expect(search_parameter_value.to_sql).to_not be_empty
    expect(search_parameter_value.to_sql[:predicates]).to eq "age is not like ?"
    expect(search_parameter_value.to_sql[:values]).to eq '%50%'
  end

  it "allows to generate sql for search values with 'presence' operators" do
    search_parameter_value.value = '50'
    search_parameter_value.operator = Discerner::Operator.find_by_symbol('none') || FactoryGirl.create(:operator, symbol: 'is not null', text: 'none', operator_type: 'presence')
    expect(search_parameter_value.to_sql).to_not be_empty
    expect(search_parameter_value.to_sql[:predicates]).to eq "age is not null"
    expect(search_parameter_value.to_sql[:values]).to be_nil
    expect(search_parameter_value).to_not be_disabled
    expect(search_parameter_value.warnings.full_messages).to be_blank
  end

  it "does not store value is presence operator is selected" do
    search_parameter_value.value = '50'
    search_parameter_value.additional_value = '50'
    search_parameter_value.parameter_value = FactoryGirl.create(:parameter_value, parameter: search_parameter_value.search_parameter.parameter)

    expect(search_parameter_value).to be_valid
    expect(search_parameter_value.value).to_not be_blank
    expect(search_parameter_value.additional_value).to_not be_blank

    search_parameter_value.operator = Discerner::Operator.find_by_symbol('none') || FactoryGirl.create(:operator, symbol: 'is not null', text: 'none', operator_type: 'presence')
    expect(search_parameter_value).to be_valid
    expect(search_parameter_value.value).to be_blank
    expect(search_parameter_value.additional_value).to be_blank
  end

  it "detects if value is blank" do
    expect(search_parameter_value).to_not be_disabled
    expect(search_parameter_value.warnings.full_messages).to be_blank
    search_parameter_value.value = nil
    expect(search_parameter_value).to be_disabled
    expect(search_parameter_value.warnings.full_messages).to include('Parameter value has to be selected')
  end

  it "detects if chosen value is deleted" do
    search_parameter_value.search_parameter.parameter.parameter_type.name = 'list'
    search_parameter_value.parameter_value = FactoryGirl.create(:parameter_value, parameter: search_parameter_value.search_parameter.parameter)

    search_parameter_value.parameter_value.deleted_at = Time.now
    expect(search_parameter_value).to be_disabled
    expect(search_parameter_value.warnings.full_messages).to_not be_blank

    search_parameter_value.chosen = true
    expect(search_parameter_value).to be_disabled
    expect(search_parameter_value.warnings.full_messages).to include('Parameter value has been deleted and has to be removed from the search')

    search_parameter_value.search_parameter.parameter.parameter_type.name = 'combobox'
    expect(search_parameter_value).to be_disabled
    expect(search_parameter_value.warnings.full_messages).to include('Parameter value has been deleted and has to be removed from the search')

    search_parameter_value.search_parameter.parameter.parameter_type.name = 'exclusive_list'
    expect(search_parameter_value).to be_disabled
    expect(search_parameter_value.warnings.full_messages).to include('Parameter value has been deleted and has to be removed from the search')
  end

  it "detects if search parameter value is in a wrong format" do
    search_parameter_value.search_parameter.parameter.parameter_type.name = 'date'
    search_parameter_value.value = '99-99-009'
    expect(search_parameter_value).to be_disabled
    expect(search_parameter_value.warnings.full_messages).to include('Provided date is not valid')

    search_parameter_value.additional_value = '99-99-009'
    expect(search_parameter_value).to be_disabled
    expect(search_parameter_value.warnings.full_messages).to include('Provided date is not valid')

    search_parameter_value.value = '01-02-2003'
    expect(search_parameter_value).to be_disabled
    expect(search_parameter_value.warnings.full_messages).to include('Provided date is not valid')

    search_parameter_value.additional_value = '01-02-2003'
    expect(search_parameter_value).to_not be_disabled
    expect(search_parameter_value.warnings.full_messages).to be_blank

    #search_parameter_value.value = '01---02-2003'
    #expect(search_parameter_value).to be_disabled
    #expect(search_parameter_value.warnings.full_messages).to include('Provided date is not valid')

    search_parameter_value.value = 'xx'
    expect(search_parameter_value).to be_disabled
    expect(search_parameter_value.warnings.full_messages).to include('Provided date is not valid')

    search_parameter_value.value = '09-09-0912'
    expect(search_parameter_value).to be_disabled
    expect(search_parameter_value.warnings.full_messages).to include('Provided date is not valid')
  end

  it "detects if combobox parameter value is not selected" do
    expect(search_parameter_value).to_not be_disabled
    search_parameter_value.search_parameter.parameter.parameter_type.name = 'combobox'
    search_parameter_value.operator = nil
    search_parameter_value.parameter_value_id = nil
    expect(search_parameter_value).to be_disabled
  end

  it "self-destroyes if belongs to list parameter and references deleted value and not chosen" do
    search_parameter_value.parameter_value = FactoryGirl.create(:parameter_value, parameter: search_parameter_value.search_parameter.parameter)
    search_parameter_value.parameter_value.deleted_at = Time.now
    search_parameter_value.chosen = false
    search_parameter_value.save
    expect(search_parameter_value.class).to exist(search_parameter_value)

    search_parameter_value.search_parameter.parameter.parameter_type.name = 'list'
    search_parameter_value.save
    expect(search_parameter_value.class).to_not exist(search_parameter_value)
  end

  describe "it marks coddesponding search as updated on change" do
    it "is not triggered on save with no changes" do
      updated_datestamp = search_parameter_value.search_parameter.search.updated_at
      search_parameter_value.save
      expect(search_parameter_value.search_parameter.search.updated_at).to eq(updated_datestamp)
    end

    it "detects new search_parameter_value" do
      updated_datestamp = search_parameter_value.search_parameter.search.updated_at
      FactoryGirl.create(:search_parameter_value, search_parameter: search_parameter_value.search_parameter, operator: Discerner::Operator.last)
      expect(search_parameter_value.search_parameter.search.updated_at).to be > updated_datestamp
    end

    it "detects search_parameter_value value change" do
      updated_datestamp = search_parameter_value.search_parameter.search.updated_at

      search_parameter_value.value = 'xx'
      search_parameter_value.save!
      expect(search_parameter_value.search_parameter.search.updated_at).to be > updated_datestamp
    end

    it "detects search_parameter_value parameter value change" do
      updated_datestamp = search_parameter_value.search_parameter.search.updated_at
      search_parameter_value.parameter_value = FactoryGirl.create(:parameter_value, parameter: search_parameter_value.search_parameter.parameter)
      search_parameter_value.save!
      expect(search_parameter_value.search_parameter.search.updated_at).to be > updated_datestamp
    end

    it "detects search_parameter_value removal" do
      search = search_parameter_value.search_parameter.search
      updated_datestamp = search.updated_at
      search_parameter_value.destroy
      expect(search.updated_at).to be > updated_datestamp
    end
  end
end
