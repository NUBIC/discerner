module Discerner
  module ExportParameterCustomMethods
  end

  class ExportParameter < ActiveRecord::Base
    include Discerner::Methods::Models::ExportParameter
    include Discerner::ExportParameterCustomMethods
  end
end
