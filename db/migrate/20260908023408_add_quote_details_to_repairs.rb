class AddQuoteDetailsToRepairs < ActiveRecord::Migration[8.1]
  def change
    add_column :repairs, :quoted_at, :datetime
    change_column_null :repairs, :status, false
  end
end