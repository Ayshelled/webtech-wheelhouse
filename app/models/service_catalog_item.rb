class ServiceCatalogItem < ApplicationRecord
	has_many :repair_line_items, -> { by_repair }, dependent: :restrict_with_error
	has_many :repairs, through: :repair_line_items, dependent: :restrict_with_error

	scope :by_name, -> { order(:name) }

	validates :name, presence: true, uniqueness: true
	validates :price, presence: true, numericality: { greater_than: 0 }
end