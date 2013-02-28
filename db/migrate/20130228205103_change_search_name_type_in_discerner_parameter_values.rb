class ChangeSearchNameTypeInDiscernerParameterValues < ActiveRecord::Migration
  def self.up
    change_column :discerner_parameter_values, :name, :string, :limit => 1000
   end

  def self.down
    change_column :discerner_parameter_values, :name, :string
  end
end
