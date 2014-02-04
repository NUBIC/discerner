class CreateDiscernerParameterValueCategories < ActiveRecord::Migration
  def change
    create_table :discerner_parameter_value_categories do |t|
      t.integer :parameter_id
      t.string :name
      t.string :unique_identifier
      t.integer :display_order
      t.datetime :deleted_at
      t.boolean :collapse

      t.timestamps
    end

    add_index :discerner_parameter_value_categories, [:parameter_id, :unique_identifier, :deleted_at], :unique => true, :name => 'discerner_parameter_value_categories_uniq_index'
  end
end
