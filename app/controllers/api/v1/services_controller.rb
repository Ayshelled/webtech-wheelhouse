module Api
  module V1
    class ServicesController < Api::BaseController
      before_action :authenticate_api_token!, only: :create

      def index
        services = ServiceCatalogItem.includes(:repair_line_items).by_name
        render json: services.map { |service| service_document(service) }
      end

      def show
        service = ServiceCatalogItem.includes(:repair_line_items).find(params[:id])
        render json: service_document(service)
      end

      def create
        service = ServiceCatalogItem.new(service_catalog_item_params)

        if service.save
          render json: service_document(service),
            status: :created,
            location: api_v1_service_url(service)
        else
          render json: { errors: service.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def service_catalog_item_params
        attributes = params.expect(service_catalog_item: %i[name price])
        raise ActionController::BadRequest, "No service attributes were provided." if attributes.empty?

        attributes
      end

      def service_document(service)
        {
          id: service.id,
          name: service.name,
          price: decimal_string(service.price),
          times_charged: service.repair_line_items.size
        }
      end
    end
  end
end
