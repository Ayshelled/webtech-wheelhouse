class ServiceCatalogItemsController < ApplicationController
  def index
    @service_catalog_items = ServiceCatalogItem.by_name
  end

  def show
    @service_catalog_item = ServiceCatalogItem.includes(repair_line_items: :repair).find(params[:id])
  end
end