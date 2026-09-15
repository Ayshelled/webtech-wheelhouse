class ServiceCatalogItemsController < ApplicationController
  def index
    @service_catalog_items = ServiceCatalogItem.order(:name)
  end

  def show
    @service_catalog_item = ServiceCatalogItem.find(params[:id])
  end
end