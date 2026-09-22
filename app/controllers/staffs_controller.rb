class StaffsController < ApplicationController
  def index
    @staffs = Staff.by_name
  end

  def show
    @staff = Staff.includes(intake_repairs: {}, assigned_repairs: {}).find(params[:id])
  end
end