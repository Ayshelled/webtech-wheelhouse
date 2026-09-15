class AddForeignKeys < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :bikes, :customers
    add_foreign_key :repairs, :bikes
    add_foreign_key :repairs, :staffs, column: :intake_staff_id
    add_foreign_key :repairs, :staffs, column: :assigned_staff_id
    add_foreign_key :repair_line_items, :repairs
    add_foreign_key :repair_line_items, :service_catalog_items
  end
end