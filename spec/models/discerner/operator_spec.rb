require 'spec_helper'

describe Discerner::Operator do
  let!(:operator) { Factory.create(:operator) }

  it "is valid with valid attributes" do
    operator.should be_valid
  end
  
  it "validates that operator has a name" do
    c = Discerner::Operator.new()
    c.should_not be_valid
    c.errors.full_messages.should include 'Symbol can\'t be blank'
  end
  
  it "validates uniqueness of symbol for not-deleted records" do
    d = Discerner::Operator.new(:symbol => operator.symbol)
    d.should_not be_valid
    d.errors.full_messages.should include 'Symbol for operator has already been taken'
  end
  
  it "do not allow to reuse symbol if record has been deleted" do
    d = Discerner::Operator.new(:symbol => operator.symbol, :deleted_at => Time.now)
    d.should_not be_valid
    
    Factory.create(:operator, :symbol => '<', :deleted_at => Time.now)
    d = Discerner::Operator.new(:symbol => '<')
    d.should_not be_valid
    
    d.deleted_at = Time.now
    d.should_not be_valid
  end
  
  it "allows to access matching parameter types" do
    operator.should respond_to :parameter_types
  end
end
