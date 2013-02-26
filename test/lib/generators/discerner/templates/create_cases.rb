class CreateCases < ActiveRecord::Migration
  def change
    create_table :cases do |t|
      t.datetime :accessioned_dt_tm

      t.timestamps
    end
  end
end
