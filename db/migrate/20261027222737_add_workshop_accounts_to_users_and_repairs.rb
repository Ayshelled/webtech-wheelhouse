class AddWorkshopAccountsToUsersAndRepairs < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, default: "counter", null: false
    add_reference :users, :staff, foreign_key: true, index: { unique: true }
    remove_index :users, :email_address
    add_index :users, "LOWER(email_address)", unique: true, name: "index_users_on_lower_email_address"
    add_reference :repairs, :intake_user, foreign_key: { to_table: :users }
  end
end
