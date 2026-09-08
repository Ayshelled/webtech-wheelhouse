class CreateRepairs < ActiveRecord::Migration[8.1]
  def change
    create_table :repairs do |t|
      t.references :bike, null: false, foreign_key: false
      t.references :intake_staff, null: false, foreign_key: false
      t.references :assigned_staff, null: true, foreign_key: false
      t.string :status, default: "Tagged"
      t.date :promised_on, null: false
      t.boolean :customer_approved
      t.datetime :approved_at
      t.datetime :handed_back_at

      t.timestamps
    end
  end
end
