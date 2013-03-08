class AddDeletedAtToDiscernerSearchCombinations < ActiveRecord::Migration
  def change
    add_column :discerner_search_combinations, :deleted_at, :datetime
  end
end
