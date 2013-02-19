class AddExclusiveToDiscernerParameters < ActiveRecord::Migration
  def change
    add_column :discerner_parameters, :exclusive, :boolean
  end
end
