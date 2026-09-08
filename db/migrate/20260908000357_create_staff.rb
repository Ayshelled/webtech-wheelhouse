class CreateStaff < ActiveRecord::Migration[8.1]
  def change
    create_table :staffs do |t|
      t.string :name, null: false
      t.string :role, null: false

      t.timestamps
    end
  end
end
