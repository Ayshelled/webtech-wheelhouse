class Bike < ApplicationRecord
	belongs_to :customer
	has_many :repairs, -> { by_promised_on }, dependent: :destroy

	scope :by_name, -> { order(:make, :model, :serial_number) }

	before_validation :normalize_serial_number

	validates :customer, :make, :model, :serial_number, presence: true
	validates :serial_number, uniqueness: true

	private

	def normalize_serial_number
		self.serial_number = serial_number.to_s.strip.upcase
	end
end