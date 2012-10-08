class CreateDiscernerParameters < ActiveRecord::Migration
  def change
    create_table :discerner_parameters do |t|
      t.string   :name
      t.datetime :deleted_at
      t.integer  :parameter_category_id
      t.integer  :parameter_type_id
      t.string   :database_name

      t.timestamps
    end
    add_index :discerner_parameters, [:database_name, :deleted_at], :unique => true, :name => 'index_discerner_parameters'
  end
end
