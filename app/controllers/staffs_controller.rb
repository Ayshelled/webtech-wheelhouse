class StaffsController < ApplicationController
  before_action :set_staff, only: %i[show edit update destroy]

  def index
    authorize Staff
    @staffs = policy_scope(Staff).by_name
  end

  def show
    authorize @staff
    visible_repairs = policy_scope(Repair)
    @intake_repairs = @staff.intake_repairs.merge(visible_repairs)
    @assigned_repairs = @staff.assigned_repairs.merge(visible_repairs)
  end

  def new
    authorize Staff
    @staff = Staff.new
  end

  def edit
    authorize @staff
  end

  def create
    authorize Staff
    @staff = Staff.new(staff_params)
    if @staff.save
      redirect_to @staff, notice: "Staff member #{@staff.name} was created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @staff
    if @staff.update(staff_params)
      redirect_to @staff, notice: "Staff member #{@staff.name} was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @staff
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
