class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :gender

      t.timestamps
    end
  end
end
