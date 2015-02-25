require 'spec_helper'

describe Discerner::SearchNamespace do
  let!(:search) {
    s = FactoryGirl.build(:search)
    s.search_parameters << FactoryGirl.build(:search_parameter, search: s)
    s.dictionary = Discerner::Dictionary.last
    s.save!
    s
  }

  it "allows to namespace searches" do
    class Case < ActiveRecord::Base
      has_many :discerner_search_namespaces, class_name: 'Discerner::SearchNamespace', as: :namespace
      has_many :discerner_searches, through: :discerner_search_namespaces, source: :search, class_name: 'Discerner::Search'
    end

    module Discerner
      class Search < ActiveRecord::Base
        include Discerner::Methods::Models::Search
        has_many :cases,  through: :search_namespaces, source_type: 'Case', source: :namespace
        has_many :events, through: :search_namespaces, source_type: 'Event', source: :namespace
      end
    end

    s = search
    e = Event.create!
    expect(e.discerner_searches).to be_empty
    expect(s.events).to be_empty
    expect(s.cases).to be_empty

    e.discerner_searches << s

    expect(e.discerner_searches.length).to eq 1
    expect(e.discerner_search_namespaces.length).to eq 1
    expect(s.events).not_to be_empty
    expect(s.events.length).to eq 1
    expect(s.cases).to be_empty

    c = Case.create!
    expect(c.discerner_searches).to be_empty

    c.discerner_searches << s

    expect(c.discerner_searches.length).to eq 1
    expect(c.discerner_search_namespaces.length).to eq 1
    expect(s.events).not_to be_empty
    expect(s.events.length).to eq 1
    expect(s.cases).not_to be_empty
    expect(s.cases.length).to eq 1

    s1 = FactoryGirl.build(:search)
    s1.search_parameters << FactoryGirl.build(:search_parameter, search: s1, parameter: FactoryGirl.build(:parameter, search_method: 'yet_another_parameter'))

    s1.dictionary = Discerner::Dictionary.last
    s1.save!

    s1.cases << c
    s1.events << e

    expect(c.reload.discerner_searches.length).to eq 2
    expect(e.reload.discerner_searches.length).to eq 2
  end
end