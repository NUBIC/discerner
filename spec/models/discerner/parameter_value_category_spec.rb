require 'spec_helper'

module Discerner
  describe ParameterValueCategory do
    let!(:parameter_value_category) { FactoryGirl.create(:parameter_value_category) }

    it "is valid with valid attributes" do
      parameter_value_category.should be_valid
    end

    it "validates that parameter value category has name" do
      c = Discerner::ParameterValueCategory.new()
      c.should_not be_valid
      c.errors.full_messages.should include 'Name can\'t be blank'
    end

    it "validates that parameter value category is linked to a parameter" do
      c = Discerner::ParameterValueCategory.new()
      c.should_not be_valid
      c.errors.full_messages.should include 'Parameter can\'t be blank'
    end

    it "validates that parameter value category has a unique identifier" do
      c = Discerner::ParameterValueCategory.new()
      c.should_not be_valid
      c.errors.full_messages.should include 'Unique identifier can\'t be blank'
    end

    it "validates uniqueness of unique identifier for not-deleted records linked to the same parameter" do
      c = Discerner::ParameterValueCategory.new(:unique_identifier => parameter_value_category.unique_identifier, :name => parameter_value_category.name, :parameter => parameter_value_category.parameter)
      c.should_not be_valid
      c.errors.full_messages.should include 'Unique identifier for parameter value category has already been taken'
    end

    it "allows to reuse unique identifier if record has been deleted" do
      c = Discerner::ParameterValueCategory.new(:unique_identifier => parameter_value_category.unique_identifier, :name => parameter_value_category.name, :parameter => parameter_value_category.parameter)
      c.should_not be_valid

      parameter_value_category.deleted_at = Time.now
      parameter_value_category.save
      c.should be_valid
    end

    it "allows to reuse unique identifier with different parameter" do
      c = Discerner::ParameterValueCategory.new(:unique_identifier => parameter_value_category.unique_identifier, :name => parameter_value_category.name, :parameter => FactoryGirl.create(:parameter, :unique_identifier => 'blah'))
      c.should be_valid
    end

    it "allows to access parameter values for parameter value category" do
      parameter_value_category.should respond_to :parameter_values
    end

    it "detects if record has been marked as deleted" do
      parameter_value_category.deleted_at = Time.now
      parameter_value_category.should be_deleted
    end

    it "does not allow to add value linked to different parameter" do
      v = FactoryGirl.create(:parameter_value, :parameter => FactoryGirl.create(:parameter, :unique_identifier => 'blah'))
      parameter_value_category.parameter_values << v
      parameter_value_category.should_not be_valid
      parameter_value_category.errors.full_messages.should include "Parameter value #{v.name} does not belong to parameter #{parameter_value_category.parameter.name}"
    end
  end
end
