class RepairsController < ApplicationController
  before_action :set_repair, only: %i[show edit update destroy remove_photo]
  before_action :load_form_options, only: %i[new edit create update]

  def index
    authorize Repair
    @repairs = policy_scope(Repair).with_attached_photos.with_rich_text_diagnosis
      .includes({ intake_user: :staff }, bike: :customer).by_promised_on
  end

  def show
    authorize @repair
  end

  def new
    authorize Repair
    @repair = Repair.new(bike: Bike.find_by(id: params[:bike_id]))
    3.times { @repair.repair_line_items.build }
  end

  def edit
    authorize @repair
    3.times { @repair.repair_line_items.build }
  end

  def create
    authorize Repair
    @repair = Repair.new(repair_params)
    @repair.intake_user = Current.user
    if @repair.save
      redirect_to @repair, notice: "Repair ##{@repair.id} was created."
    else
      ensure_empty_line_slots
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @repair
    attributes = repair_params
    new_photos = Array(attributes.delete(:photos)).reject(&:blank?)
    @repair.assign_attributes(attributes)
    @repair.photos = @repair.photos.blobs + new_photos if new_photos.any?

    if @repair.save
      redirect_to @repair, notice: "Repair ##{@repair.id} was updated."
    else
      ensure_empty_line_slots
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @repair
    if @repair.destroy
      redirect_to repairs_path, notice: "Repair ##{@repair.id} was deleted.", status: :see_other
    else
      redirect_to @repair, alert: @repair.errors.full_messages.to_sentence
    end
  end

  def remove_photo
    authorize @repair, :remove_photo?
    @repair.photos.attachments.find(params[:photo_id]).purge
    redirect_to @repair, notice: "Intake photo was removed.", status: :see_other
  end

  private

  def set_repair
    @repair = Repair.with_attached_photos.with_rich_text_diagnosis
      .includes({ intake_user: :staff }, bike: :customer, repair_line_items: :service_catalog_item).find(params[:id])
  end

  def load_form_options
    @bikes = Bike.includes(:customer).by_name
    @staffs = Staff.by_name
    @mechanics = Staff.where(role: "Mechanic").by_name
    @services = ServiceCatalogItem.by_name
  end

  def repair_params
    params.expect(repair: policy(@repair || Repair.new).permitted_attributes)
  end

  def ensure_empty_line_slots
    (3 - @repair.repair_line_items.count(&:new_record?)).times do
      @repair.repair_line_items.build
    end
  end
end
