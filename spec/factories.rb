FactoryGirl.define do
  factory :dictionary, :class => Discerner::Dictionary do |f|
    f.name "best dictionary"
  end
  
  factory :parameter_category, :class => Discerner::ParameterCategory do |f|
    f.name "best caregory"
    f.association :dictionary
  end
end