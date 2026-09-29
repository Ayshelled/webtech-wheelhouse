class StaffsController < ApplicationController
  before_action :set_staff, only: %i[show edit update destroy]

  def index
    @staffs = Staff.by_name
  end

  def show
  end

  def new
    @staff = Staff.new
  end

  def edit
  end

  def create
    @staff = Staff.new(staff_params)
    if @staff.save
      redirect_to @staff, notice: "Staff member #{@staff.name} was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @staff.update(staff_params)
      redirect_to @staff, notice: "Staff member #{@staff.name} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @staff.destroy
      redirect_to staffs_path, notice: "Staff member #{@staff.name} was deleted.", status: :see_other
    else
      redirect_to @staff, alert: @staff.errors.full_messages.to_sentence
    end
  end

  private

  def set_staff
    @staff = Staff.includes(intake_repairs: {}, assigned_repairs: {}).find(params[:id])
  end

  def staff_params
    params.expect(staff: %i[name role])
  end
end
