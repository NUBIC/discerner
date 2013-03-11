class AddOperatorTypeToDiscernerOperators < ActiveRecord::Migration
  def change
    add_column :discerner_operators, :operator_type, :string
  end
end
