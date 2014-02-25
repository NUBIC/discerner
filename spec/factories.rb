FactoryGirl.define do
  factory :dictionary, :class => Discerner::Dictionary do |f|
    f.name "sample dictionary"
  end

  factory :parameter_category, :class => Discerner::ParameterCategory do |f|
    f.name "best caregory"
    after_build {|s|
      s.dictionary = Discerner::Dictionary.last || FactoryGirl.build(:dictionary)
    }
  end

  factory :parameter_type, :class => Discerner::ParameterType do |f|
    f.name "string"
  end

  factory :parameter, :class => Discerner::Parameter do |f|
    f.name "some parameter"
    f.unique_identifier "some_parameter"
    after_build { |s|
      s.parameter_category = Discerner::ParameterCategory.last || FactoryGirl.build(:parameter_category)
      s.parameter_type = Discerner::ParameterType.last || FactoryGirl.build(:parameter_type)
    }
  end

  factory :operator, :class => Discerner::Operator do |f|
    f.operator_type 'comparison'
    f.symbol '>'
    f.text 'is greater than'
  end

  factory :parameter_value, :class => Discerner::ParameterValue do |f|
    f.name 'some value'
    f.search_value 'some_value'
    f.association :parameter
  end

  factory :search, :class => Discerner::Search do |f|
    f.name 'some search'
    after_build {|s|
      s.dictionary = Discerner::Dictionary.last || FactoryGirl.build(:dictionary)
    }
  end

  factory :search_parameter, :class => Discerner::SearchParameter do |f|
    f.association :search
    f.association :parameter
    f.display_order 1
  end

  factory :export_parameter, :class => Discerner::ExportParameter do |f|
    f.association :search
    f.association :parameter
  end

  factory :search_parameter_value, :class => Discerner::SearchParameterValue do |f|
    f.association :search_parameter
    f.association :operator
    f.value 'hello'
    f.chosen false
    f.display_order 1
  end

  factory :search_combination, :class => Discerner::SearchCombination do |f|
    f.association :search
  end
end