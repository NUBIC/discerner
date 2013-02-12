class CreateDiscernerExportParameters < ActiveRecord::Migration
  def change
    create_table :discerner_export_parameters do |t|
      t.integer :search_id
      t.integer :parameter_id
      t.timestamps
    end
  end
end
