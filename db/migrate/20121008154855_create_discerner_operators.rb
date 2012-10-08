class CreateDiscernerOperators < ActiveRecord::Migration
  def change
    create_table :discerner_operators do |t|
      t.string :symbol
      t.string :text
      t.boolean :binary
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :discerner_operators, [:symbol, :deleted_at], :unique => true, :name => 'index_discerner_operators'
  end
end
