require 'spec_helper'
require 'rake'

describe "Rake task discerner:setup" do
  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require "lib/tasks/discerner_tasks"
    Rake::Task.define_task(:environment)
  end
  
  describe "operators" do
    it "loads database with default operators and parameter types" do
      @rake["discerner:setup:operators"].invoke
      Discerner::Operator.all.should_not be_empty
      Discerner::Operator.where(:text => 'is not like').should_not be_empty
      Discerner::ParameterType.all.should_not be_empty
    end
  end
end
  
  