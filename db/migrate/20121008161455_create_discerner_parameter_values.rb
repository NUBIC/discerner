class CreateDiscernerParameterValues < ActiveRecord::Migration
  def change
    create_table :discerner_parameter_values do |t|
      t.string :name
      t.string :database_name
      t.datetime :deleted_at
      t.integer :parameter_id

      t.timestamps
    end
    add_index :discerner_parameter_values, [:database_name, :parameter_id, :deleted_at], :unique => true, :name => 'index_discerner_parameter_values'
  end
end
