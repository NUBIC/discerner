class ChangeSearchValueTypeInDiscernerParameterValues < ActiveRecord::Migration
  def self.up
   change_column :discerner_parameter_values, :search_value, :text, :limit => 1000
  end

  def self.down
   change_column :discerner_parameter_values, :search_value, :string
  end
end
