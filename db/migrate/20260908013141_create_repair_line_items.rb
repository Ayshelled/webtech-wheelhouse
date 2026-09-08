class CreateRepairLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :repair_line_items do |t|
      t.references :repair, null: false, foreign_key: false
      t.references :service_catalog_item, null: false, foreign_key: false
      t.decimal :price_charged, null: false, precision: 10, scale: 2

      t.timestamps
    end
  end
end
