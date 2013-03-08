class AddDeletedAtToDiscernerSearchParameterValues < ActiveRecord::Migration
  def change
    add_column :discerner_search_parameter_values, :deleted_at, :datetime
  end
end
