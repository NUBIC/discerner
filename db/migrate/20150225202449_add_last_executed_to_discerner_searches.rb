class AddLastExecutedToDiscernerSearches < ActiveRecord::Migration
  def change
    add_column :discerner_searches, :last_executed, :datetime
  end
end
