class Staff < ApplicationRecord
    has_many :intake_repairs, -> { by_promised_on }, class_name: "Repair", foreign_key: :intake_staff_id, dependent: :restrict_with_error
    has_many :assigned_repairs, -> { by_promised_on }, class_name: "Repair", foreign_key: :assigned_staff_id, dependent: :restrict_with_error

    scope :by_name, -> { order(:name) }

    validates :name, :role, presence: true
end