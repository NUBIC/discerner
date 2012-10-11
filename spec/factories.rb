FactoryGirl.define do
  factory :dictionary, :class => Discerner::Dictionary do |f|
    f.name "best dictionary"
  end
  
  factory :parameter_category, :class => Discerner::ParameterCategory do |f|
    f.name "best caregory"
    f.association :dictionary
  end
  
  factory :parameter_type, :class => Discerner::ParameterType do |f|
    f.name "some type"
  end
  
  factory :parameter, :class => Discerner::Parameter do |f|
    f.name "some parameter"
    f.database_name "some parameter"
    f.association :parameter_category
    f.association :parameter_type
  end
  
  factory :operator, :class => Discerner::Operator do |f|
    f.symbol '>'
    f.text 'is greater than'
  end

  factory :parameter_value, :class => Discerner::ParameterValue do |f|
    f.name 'some value'
    f.database_name 'some_value'
    f.association :parameter
  end
  
  factory :search, :class => Discerner::Search do |f|
    f.name 'some search'
    f.username 'me'
  end
  
  factory :search_parameter, :class => Discerner::SearchParameter do |f|
    f.association :search
    f.association :parameter
    f.display_order 1
  end
  
  factory :search_parameter_value, :class => Discerner::SearchParameterValue do |f|
    f.association :search_parameter
    f.association :operator
    f.value 'hello'
    f.additional_value 'world'
    f.chosen false
    f.display_order 1
  end
end