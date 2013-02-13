class RenameDatabaseNameToSearchValueInDiscernerParameterValues < ActiveRecord::Migration
  def change
    rename_column :discerner_parameter_values, :database_name, :search_value
  end
end
