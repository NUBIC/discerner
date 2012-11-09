module Discerner
  module ApplicationHelper
    def user_for_discerner
      current_user rescue nil
    end
  end
end
