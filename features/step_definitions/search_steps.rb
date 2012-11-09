Given /^search dictionary is loaded$/ do
  file = 'lib/setup/operators.yml'
  parser = Discerner::Parser.new()
  parser.parse_operators(File.read(file))
end

Given /^search "([^"]*)" exists$/ do |name|
  s = Factory.build(:search, :name => name)
  s.search_parameters << Factory.build(:search_parameter, :search => s, :parameter => Discerner::Parameter.first)
  s.save!
end
