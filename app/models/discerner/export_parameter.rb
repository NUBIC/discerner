module Discerner
  class ExportParameter < ActiveRecord::Base
    unloadable
    include Discerner::Methods::Models::ExportParameter
  end
end
