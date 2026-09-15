class BikesController < ApplicationController
  def index
    @bikes = Bike.includes(:customer).order(:make, :model, :serial_number)
  end

  def show
    @bike = Bike.find(params[:id])
  end
end