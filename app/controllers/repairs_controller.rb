class RepairsController < ApplicationController
  before_action :set_repair, only: %i[show edit update destroy]
  before_action :load_form_options, only: %i[new edit create update]

  def index
    @repairs = Repair.includes(bike: :customer).by_promised_on
  end

  def show
  end

  def new
    @repair = Repair.new(bike: Bike.find_by(id: params[:bike_id]))
    3.times { @repair.repair_line_items.build }
  end

  def edit
    3.times { @repair.repair_line_items.build }
  end

  def create
    @repair = Repair.new(repair_params)
    if @repair.save
      redirect_to @repair, notice: "Repair ##{@repair.id} was created."
    else
      ensure_empty_line_slots
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @repair.update(repair_params)
      redirect_to @repair, notice: "Repair ##{@repair.id} was updated."
    else
      ensure_empty_line_slots
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @repair.destroy
      redirect_to repairs_path, notice: "Repair ##{@repair.id} was deleted.", status: :see_other
    else
      redirect_to @repair, alert: @repair.errors.full_messages.to_sentence
    end
  end

  private

  def set_repair
    @repair = Repair.includes(bike: :customer, repair_line_items: :service_catalog_item).find(params[:id])
  end

  def load_form_options
    @bikes = Bike.includes(:customer).by_name
    @staffs = Staff.by_name
    @mechanics = Staff.where(role: "Mechanic").by_name
    @services = ServiceCatalogItem.by_name
  end

  def repair_params
    params.expect(repair: [
      :bike_id, :intake_staff_id, :assigned_staff_id, :promised_on, :status,
      :customer_approved, :approved_at, :quoted_at, :handed_back_at,
      repair_line_items_attributes: [ [ :id, :service_catalog_item_id, :price_charged, :_destroy ] ]
    ])
  end

  def ensure_empty_line_slots
    (3 - @repair.repair_line_items.count(&:new_record?)).times do
      @repair.repair_line_items.build
    end
  end
end
