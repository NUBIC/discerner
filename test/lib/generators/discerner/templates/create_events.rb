class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.datetime :accessioned_dt_tm

      t.timestamps
    end
  end
end
