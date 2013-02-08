class CreateDiscernerSearchCombinations < ActiveRecord::Migration
  def change
    create_table :discerner_search_combinations do |t|
      t.integer :search_id
      t.integer :combined_search_id
      t.integer :operator_id
      t.integer :display_order

      t.timestamps
    end
  end
end
