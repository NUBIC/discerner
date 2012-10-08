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
end