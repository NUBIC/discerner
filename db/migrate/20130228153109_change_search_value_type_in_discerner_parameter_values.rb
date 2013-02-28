class ChangeSearchValueTypeInDiscernerParameterValues < ActiveRecord::Migration
  def self.up
    remove_index :discerner_parameter_values, :name => 'index_discerner_parameter_values'
    change_column :discerner_parameter_values, :search_value, :string, :limit => 1000
    add_index :discerner_parameter_values, [:search_value, :parameter_id, :deleted_at], :unique => true, :name => 'index_discerner_parameter_values'
  end

  def self.down
    remove_index :discerner_parameter_values, :name => 'index_discerner_parameter_values'
    change_column :discerner_parameter_values, :search_value, :string
    add_index :discerner_parameter_values, [:search_value, :parameter_id, :deleted_at], :unique => true, :name => 'index_discerner_parameter_values'
  end
end
