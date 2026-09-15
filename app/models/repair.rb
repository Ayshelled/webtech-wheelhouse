class Repair < ApplicationRecord
    belongs_to :bike
    belongs_to :intake_staff, class_name: "Staff"
    belongs_to :assigned_staff, class_name: "Staff", optional: true
    has_many :repair_line_items
end