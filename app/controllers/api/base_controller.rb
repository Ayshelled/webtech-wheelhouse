module Api
  class BaseController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    rescue_from ActionController::BadRequest, with: :render_bad_request
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_bad_request
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

    private

    def authenticate_api_token!
      authenticated = authenticate_with_http_token do |token, _options|
        expected_token = Rails.application.credentials.dig(:api, :token)
        expected_token.is_a?(String) &&
          ActiveSupport::SecurityUtils.secure_compare(token, expected_token)
      end
      return if authenticated

      headers["WWW-Authenticate"] = 'Bearer realm="Wheelhouse API"'
      render_error("Missing or invalid bearer token.", status: :unauthorized)
    end

    def render_bad_request(error)
      message = error.message.presence || "Bad request."
      render_error(message, status: :bad_request)
    end

    def render_not_found(_error)
      render_error("Record not found.", status: :not_found)
    end

    def render_error(message, status:)
      render json: { errors: [ message ] }, status: status
    end

    def decimal_string(amount)
      whole, fraction = amount.to_s("F").split(".", 2)
      "#{whole}.#{fraction.to_s.ljust(2, "0")}"
    end
  end
end
