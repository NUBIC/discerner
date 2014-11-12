require 'haml'
require 'jquery-rails'

module Discerner
  class Engine < ::Rails::Engine
    isolate_namespace Discerner
    root = File.expand_path('../../', __FILE__)
    config.autoload_paths << root
    config.generators do |g|
      g.test_framework   :rspec
      g.integration_tool :rspec
      g.template_engine  :haml
    end
  end
end
