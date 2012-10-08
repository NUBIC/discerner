class CreateDiscernerParameterCategories < ActiveRecord::Migration
  def change
    create_table :discerner_parameter_categories do |t|
      t.integer  :dictionary_id, :null => false
      t.string   :name, :null => false
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :discerner_parameter_categories, [:name, :dictionary_id, :deleted_at], :unique => true, :name => 'index_discerner_parameter_categories'
  end
end
