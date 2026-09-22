class BikesController < ApplicationController
  def index
    @bikes = Bike.includes(:customer).by_name
  end

  def show
    @bike = Bike.includes(:customer, repairs: { bike: :customer }).find(params[:id])
  end
end