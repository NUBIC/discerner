class AddNamespaceToDiscernerSearches < ActiveRecord::Migration
  def change
    add_column :discerner_searches, :namespace_id, :integer
    add_column :discerner_searches, :namespace_type, :string
  end
end
