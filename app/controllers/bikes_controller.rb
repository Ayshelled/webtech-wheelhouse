class BikesController < ApplicationController
  before_action :set_bike, only: %i[show edit update destroy]
  before_action :load_form_options, only: %i[new edit create update]

  def index
    authorize Bike
    @bikes = policy_scope(Bike).includes(:customer).by_name
  end

  def show
    authorize @bike
    @repairs = policy_scope(Repair).where(bike_id: @bike.id)
      .with_attached_photos.with_rich_text_diagnosis
      .includes({ intake_user: :staff }, bike: :customer).by_promised_on
  end

  def new
    authorize Bike
    @bike = Bike.new(customer: Customer.find_by(id: params[:customer_id]))
  end

  def edit
    authorize @bike
  end

  def create
    authorize Bike
    @bike = Bike.new(bike_params)
    if @bike.save
      redirect_to @bike, notice: "Bike #{@bike.serial_number} was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @bike
    if @bike.update(bike_params)
      redirect_to @bike, notice: "Bike #{@bike.serial_number} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @bike
    if @bike.destroy
      redirect_to bikes_path, notice: "Bike #{@bike.serial_number} was deleted.", status: :see_other
    else
      redirect_to @bike, alert: @bike.errors.full_messages.to_sentence
    end
  end

  private

  def set_bike
    @bike = Bike.includes(:customer).find(params[:id])
  end

  def load_form_options
    @customers = Customer.by_name
  end

  def bike_params
    params.expect(bike: %i[customer_id make model serial_number])
  end
end
