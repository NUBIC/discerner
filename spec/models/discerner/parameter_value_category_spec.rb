require 'spec_helper'

module Discerner
  describe ParameterValueCategory do
    let!(:parameter_value_category) { FactoryGirl.create(:parameter_value_category) }

    it "is valid with valid attributes" do
      expect(parameter_value_category).to be_valid
    end

    it "validates that parameter value category has name" do
      c = Discerner::ParameterValueCategory.new()
      expect(c).to_not be_valid
      expect(c.errors.full_messages).to include 'Name can\'t be blank'
    end

    it "validates that parameter value category is linked to a parameter" do
      c = Discerner::ParameterValueCategory.new()
      expect(c).to_not be_valid
      expect(c.errors.full_messages).to include 'Parameter can\'t be blank'
    end

    it "validates that parameter value category has a unique identifier" do
      c = Discerner::ParameterValueCategory.new()
      expect(c).to_not be_valid
      expect(c.errors.full_messages).to include 'Unique identifier can\'t be blank'
    end

    it "validates uniqueness of unique identifier for not-deleted records linked to the same parameter" do
      c = Discerner::ParameterValueCategory.new(:unique_identifier => parameter_value_category.unique_identifier, :name => parameter_value_category.name, :parameter => parameter_value_category.parameter)
      expect(c).to_not be_valid
      expect(c.errors.full_messages).to include 'Unique identifier for parameter value category has already been taken'
    end

    it "allows to reuse unique identifier if record has been deleted" do
      c = Discerner::ParameterValueCategory.new(:unique_identifier => parameter_value_category.unique_identifier, :name => parameter_value_category.name, :parameter => parameter_value_category.parameter)
      expect(c).to_not be_valid

      parameter_value_category.deleted_at = Time.now
      parameter_value_category.save
      expect(c).to be_valid
    end

    it "allows to reuse unique identifier with different parameter" do
      c = Discerner::ParameterValueCategory.new(:unique_identifier => parameter_value_category.unique_identifier, :name => parameter_value_category.name, :parameter => FactoryGirl.create(:parameter, :unique_identifier => 'blah'))
      expect(c).to be_valid
    end

    it "allows to access parameter values for parameter value category" do
      expect(parameter_value_category).to respond_to :parameter_values
    end

    it "detects if record has been marked as deleted" do
      parameter_value_category.deleted_at = Time.now
      expect(parameter_value_category).to be_deleted
    end

    it "does not allow to add value linked to different parameter" do
      v = FactoryGirl.create(:parameter_value, :parameter => FactoryGirl.create(:parameter, :unique_identifier => 'blah'))
      parameter_value_category.parameter_values << v
      expect(parameter_value_category).to_not be_valid
      expect(parameter_value_category.errors.full_messages).to include "Parameter value #{v.name} does not belong to parameter #{parameter_value_category.parameter.name}"
    end
  end
end
