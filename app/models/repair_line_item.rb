class RepairLineItem < ApplicationRecord
	belongs_to :repair
	belongs_to :service_catalog_item

	scope :by_repair, -> { order(:id) }

	validates :repair, :service_catalog_item, presence: true
	validates :price_charged, presence: true, numericality: { greater_than: 0 }
end