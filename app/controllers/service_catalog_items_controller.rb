class ServiceCatalogItemsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  before_action :set_service_catalog_item, only: %i[show edit update destroy]

  def index
    authorize ServiceCatalogItem
    @service_catalog_items = policy_scope(ServiceCatalogItem).by_name
  end

  def show
    authorize @service_catalog_item
    @repair_line_items = @service_catalog_item.repair_line_items.joins(:repair)
      .merge(policy_scope(Repair)).includes(repair: { bike: :customer })
  end

  def new
    authorize ServiceCatalogItem
    @service_catalog_item = ServiceCatalogItem.new
  end

  def edit
    authorize @service_catalog_item
  end

  def create
    authorize ServiceCatalogItem
    @service_catalog_item = ServiceCatalogItem.new(service_catalog_item_params)
    if @service_catalog_item.save
      redirect_to @service_catalog_item, notice: "Service #{@service_catalog_item.name} was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @service_catalog_item
    if @service_catalog_item.update(service_catalog_item_params)
      redirect_to @service_catalog_item, notice: "Service #{@service_catalog_item.name} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @service_catalog_item
    if @service_catalog_item.destroy
      redirect_to service_catalog_items_path, notice: "Service #{@service_catalog_item.name} was deleted.", status: :see_other
    else
      redirect_to @service_catalog_item, alert: @service_catalog_item.errors.full_messages.to_sentence
    end
  end

  private

  def set_service_catalog_item
    @service_catalog_item = ServiceCatalogItem.includes(repair_line_items: :repair).find(params[:id])
  end

  def service_catalog_item_params
    params.expect(service_catalog_item: %i[name price])
  end
end
