module Api
  module V1
    class RepairsController < Api::BaseController
      before_action :authenticate_api_token!

      def index
        repairs = Repair.includes(
          { bike: :customer },
          repair_line_items: :service_catalog_item
        ).by_promised_on

        if params.key?(:state)
          state = params[:state]
          unless Repair.statuses.key?(state)
            raise ActionController::BadRequest,
              "Unknown state. Available states: #{Repair.statuses.keys.join(", ")}."
          end

          repairs = repairs.where(status: state)
        end

        render json: repairs.map { |repair| repair_document(repair) }
      end

      def show
        repair = Repair.includes(
          { bike: :customer },
          repair_line_items: :service_catalog_item
        ).find(params[:id])
        render json: repair_document(repair)
      end

      private

      def repair_document(repair)
        {
          id: repair.id,
          state: repair.status,
          checked_in_on: repair.created_at.to_date.iso8601,
          promised_on: repair.promised_on.iso8601,
          handed_back_on: repair.handed_back_at&.to_date&.iso8601,
          bike: {
            brand: repair.bike.make,
            model: repair.bike.model,
            serial_number: repair.bike.serial_number
          },
          customer: {
            name: repair.bike.customer.name
          },
          lines: repair.repair_line_items.map do |line_item|
            {
              service: line_item.service_catalog_item.name,
              price: decimal_string(line_item.price_charged)
            }
          end,
          total: decimal_string(repair.total),
          overdue: repair.overdue?,
          customer_approved: repair.customer_approved
        }
      end
    end
  end
end
