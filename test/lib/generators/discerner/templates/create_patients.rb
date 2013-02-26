class CreatePatients < ActiveRecord::Migration
  def change
    create_table :patients do |t|
      t.string :gender
      t.date   :age_at_case_collect
      t.timestamps
    end
  end
end
