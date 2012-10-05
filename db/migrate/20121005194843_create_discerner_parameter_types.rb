class CreateDiscernerParameterTypes < ActiveRecord::Migration
  def change
    create_table :discerner_parameter_types do |t|
      t.string :name
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :discerner_parameter_types, [:name, :deleted_at], :unique => true, :name => 'index_discerner_parameter_types'
  end
end
