file = File.join(Discerner::Engine.root, 'lib/setup/operators.yml')
raise "File does not exist: #{file}" unless FileTest.exists?(file)
Discerner::Parser.new(:trace => true).parse_operators(File.read(file))