class CreateServiceCatalogItems < ActiveRecord::Migration[8.1]
  def change
    create_table :service_catalog_items do |t|
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end
    add_index :service_catalog_items, :name, unique: true
  end
end
