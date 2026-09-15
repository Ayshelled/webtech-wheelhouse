class StaffsController < ApplicationController
  def index
    @staffs = Staff.order(:name)
  end

  def show
    @staff = Staff.find(params[:id])
  end
end