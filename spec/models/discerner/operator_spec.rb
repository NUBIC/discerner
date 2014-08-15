require 'spec_helper'

describe Discerner::Operator do
  let!(:operator) { FactoryGirl.create(:operator) }

  it "is valid with valid attributes" do
    expect(operator).to be_valid
  end

  it "validates that operator has a name" do
    c = Discerner::Operator.new()
    expect(c).to_not be_valid
    expect(c.errors.full_messages).to include 'Symbol can\'t be blank'
  end

  it "validates uniqueness of symbol for not-deleted records" do
    d = Discerner::Operator.new(symbol: operator.symbol)
    expect(d).to_not be_valid
    expect(d.errors.full_messages).to include 'Symbol for operator has already been taken'
  end

  it "do not allow to reuse symbol if record has been deleted" do
    d = Discerner::Operator.new(symbol: operator.symbol, deleted_at: Time.now)
    expect(d).to_not be_valid

    FactoryGirl.create(:operator, symbol: '<', deleted_at: Time.now)
    d = Discerner::Operator.new(symbol: '<')
    expect(d).to_not be_valid

    d.deleted_at = Time.now
    expect(d).to_not be_valid
  end

  it "allows to access matching parameter types" do
    expect(operator).to respond_to :parameter_types
  end

  it "detects if record has been marked as deleted" do
    operator.deleted_at = Time.now
    expect(operator).to be_deleted
  end
end
