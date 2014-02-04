class CreateDiscernerParameterValueCategorizations < ActiveRecord::Migration
  def change
    create_table :discerner_parameter_value_categorizations do |t|
      t.integer :parameter_value_category_id
      t.integer :parameter_value_id
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :discerner_parameter_value_categorizations, [:parameter_value_category_id, :parameter_value_id, :deleted_at], :unique => true, :name => 'discerner_parameter_value_categorizations_uniq_index'
  end
end
