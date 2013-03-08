class AddDeletedAtToDiscernerSearchParameters < ActiveRecord::Migration
  def change
    add_column :discerner_search_parameters, :deleted_at, :datetime
  end
end
