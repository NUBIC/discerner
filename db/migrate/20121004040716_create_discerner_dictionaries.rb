class CreateDiscernerDictionaries < ActiveRecord::Migration
  def change
    create_table :discerner_dictionaries do |t|
      t.string :name, :null => false
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :discerner_dictionaries, [:name, :deleted_at], :unique => true, :name => 'index_discerner_dictionaries'
  end
end
