class Staff < ApplicationRecord
    has_many :intake_repairs, class_name: "Repair", foreign_key: :intake_staff_id
    has_many :assigned_repairs, class_name: "Repair", foreign_key: :assigned_staff_id
end