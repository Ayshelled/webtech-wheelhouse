class CreateBikes < ActiveRecord::Migration[8.1]
  def change
    create_table :bikes do |t|
      t.references :customer, null: false, foreign_key: false
      t.string :make, null: false
      t.string :model, null: false
      t.string :serial_number, null: false

      t.timestamps
    end
    add_index :bikes, :serial_number, unique: true
  end
end
