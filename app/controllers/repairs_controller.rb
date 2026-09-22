class RepairsController < ApplicationController
  def index
    @repairs = Repair.includes(bike: :customer).by_promised_on
  end

  def show
    @repair = Repair.includes(bike: :customer, repair_line_items: :service_catalog_item).find(params[:id])
  end
end