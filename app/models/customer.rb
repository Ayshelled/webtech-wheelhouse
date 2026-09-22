class Customer < ApplicationRecord
    has_many :bikes, -> { by_name }, dependent: :restrict_with_error
    has_many :repairs, through: :bikes, dependent: :restrict_with_error

    scope :by_name, -> { order(:name) }

    validates :name, presence: { message: "Please enter the customer's name." }
    validates :phone, presence: { message: "Please enter the customer's phone number." }
end