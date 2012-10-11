class CreateDiscernerSearchParameterValues < ActiveRecord::Migration
  def change
    create_table :discerner_search_parameter_values do |t|
      t.integer :parameter_value_id
      t.integer :operator_id
      t.integer :search_parameter_id
      t.string :value
      t.string :additional_value
      t.boolean :chosen
      t.integer :display_order

      t.timestamps
    end
  end
end
