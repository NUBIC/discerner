class AddDictionaryIdToDiscernerSearches < ActiveRecord::Migration
  def change
    add_column :discerner_searches, :dictionary_id, :integer
  end
end
