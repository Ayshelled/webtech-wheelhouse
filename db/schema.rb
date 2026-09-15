# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_15_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bikes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.string "make", null: false
    t.string "model", null: false
    t.string "serial_number", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_bikes_on_customer_id"
    t.index ["serial_number"], name: "index_bikes_on_serial_number", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "phone", null: false
    t.datetime "updated_at", null: false
  end

  create_table "repair_line_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "price_charged", precision: 10, scale: 2, null: false
    t.bigint "repair_id", null: false
    t.bigint "service_catalog_item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["repair_id"], name: "index_repair_line_items_on_repair_id"
    t.index ["service_catalog_item_id"], name: "index_repair_line_items_on_service_catalog_item_id"
  end

  create_table "repairs", force: :cascade do |t|
    t.datetime "approved_at"
    t.bigint "assigned_staff_id"
    t.bigint "bike_id", null: false
    t.datetime "created_at", null: false
    t.boolean "customer_approved"
    t.datetime "handed_back_at"
    t.bigint "intake_staff_id", null: false
    t.date "promised_on", null: false
    t.datetime "quoted_at"
    t.string "status", default: "Tagged", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_staff_id"], name: "index_repairs_on_assigned_staff_id"
    t.index ["bike_id"], name: "index_repairs_on_bike_id"
    t.index ["intake_staff_id"], name: "index_repairs_on_intake_staff_id"
  end

  create_table "service_catalog_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_service_catalog_items_on_name", unique: true
  end

  create_table "staffs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "bikes", "customers"
  add_foreign_key "repair_line_items", "repairs"
  add_foreign_key "repair_line_items", "service_catalog_items"
  add_foreign_key "repairs", "bikes"
  add_foreign_key "repairs", "staffs", column: "assigned_staff_id"
  add_foreign_key "repairs", "staffs", column: "intake_staff_id"
end
