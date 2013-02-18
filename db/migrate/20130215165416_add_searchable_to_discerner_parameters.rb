class AddSearchableToDiscernerParameters < ActiveRecord::Migration
  def change
    add_column :discerner_parameters, :searchable, :boolean
  end
end
