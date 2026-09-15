class RepairLineItem < ApplicationRecord
	belongs_to :repair
	belongs_to :service_catalog_item
end