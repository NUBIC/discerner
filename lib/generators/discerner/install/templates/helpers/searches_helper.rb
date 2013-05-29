module Discerner
  module SearchesHelperCustomMethods
  end

  module SearchesHelper
    include Discerner::Methods::Helpers::SearchesHelper
    include Discerner::SearchesHelperCustomMethods
  end
end
