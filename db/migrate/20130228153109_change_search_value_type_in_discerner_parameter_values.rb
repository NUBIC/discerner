class ChangeSearchValueTypeInDiscernerParameterValues < ActiveRecord::Migration
  def self.up
    remove_index :discerner_parameter_values, :name => 'index_discerner_parameter_values'
    change_column :discerner_parameter_values, :search_value, :text, :limit => 1000
  end

  def self.down
    remove_index :discerner_parameter_values, :name => 'index_discerner_parameter_values'
    change_column :discerner_parameter_values, :search_value, :string
  end
end
