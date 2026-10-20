require "test_helper"

class ApiV1Test < ActionDispatch::IntegrationTest
  API_TOKEN = "test-api-token"

  setup do
    @customer = Customer.create!(name: "Ari Customer", phone: "555-0100")
    @bike = Bike.create!(
      customer: @customer,
      make: "Surly",
      model: "Straggler",
      serial_number: "WHEEL-001"
    )
    @staff = Staff.create!(name: "Morgan Mechanic", role: "Mechanic")
    @service = ServiceCatalogItem.create!(name: "Tune-up", price: "85.00")
    @repair = Repair.create!(
      bike: @bike,
      intake_staff: @staff,
      promised_on: Date.current + 2,
      status: :ready_for_pickup,
      customer_approved: true
    )
    RepairLineItem.create!(
      repair: @repair,
      service_catalog_item: @service,
      price_charged: "80.00"
    )
  end

  test "service collection is public, ordered, and includes charged counts with JSON content type" do
    second_service = ServiceCatalogItem.create!(name: "Wheel truing", price: "35.00")

    get "/api/v1/services", headers: { "Accept" => "text/html" }

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_equal [ @service.id, second_service.id ], response.parsed_body.map { |item| item["id"] }
    assert_equal(
      { "id" => @service.id, "name" => "Tune-up", "price" => "85.00", "times_charged" => 1 },
      response.parsed_body.first
    )
  end

  test "only the personal page origins receive CORS access to public services" do
    with_api_token do
      get "/api/v1/services", headers: { "Origin" => "http://127.0.0.1:5500" }

      assert_response :success
      assert_equal "http://127.0.0.1:5500", response.headers["Access-Control-Allow-Origin"]

      get "/api/v1/services", headers: { "Origin" => "https://ayshelled.github.io" }

      assert_response :success
      assert_equal "https://ayshelled.github.io", response.headers["Access-Control-Allow-Origin"]

      get "/api/v1/services", headers: { "Origin" => "https://other.example" }

      assert_response :success
      assert_nil response.headers["Access-Control-Allow-Origin"]

      get "/api/v1/services", headers: { "Origin" => "http://localhost:5500" }

      assert_response :success
      assert_nil response.headers["Access-Control-Allow-Origin"]

      get "/api/v1/repairs", headers: {
        "Origin" => "http://127.0.0.1:5500",
        "Authorization" => "Bearer #{API_TOKEN}"
      }
      assert_response :success
      assert_nil response.headers["Access-Control-Allow-Origin"]
    end
  end

  test "repair collection requires a token and returns the repair document" do
    with_api_token do
      get "/api/v1/repairs"
      assert_response :unauthorized
      assert_equal({ "errors" => [ "Missing or invalid bearer token." ] }, response.parsed_body)

      get "/api/v1/repairs", headers: { "Authorization" => "Bearer wrong-token" }
      assert_response :unauthorized
      assert_equal [ "errors" ], response.parsed_body.keys

      get "/api/v1/repairs", headers: authorization_headers
      assert_response :success
      assert_equal "ready_for_pickup", response.parsed_body.first["state"]
      assert_equal "Surly", response.parsed_body.first.dig("bike", "brand")
      assert_equal "Ari Customer", response.parsed_body.first.dig("customer", "name")
      assert_equal "80.00", response.parsed_body.first.dig("lines", 0, "price")
      assert_equal "80.00", response.parsed_body.first["total"]
      assert_not response.parsed_body.first.key?("bike_id")
      assert_not response.parsed_body.first.dig("customer").key?("phone")
    end
  end

  test "repair collection filters by enum state and reports unknown states as bad requests" do
    with_api_token do
      get "/api/v1/repairs?state=ready_for_pickup", headers: authorization_headers
      assert_response :success
      assert_equal [ @repair.id ], response.parsed_body.map { |repair| repair["id"] }

      get "/api/v1/repairs?state=unknown", headers: authorization_headers
      assert_response :bad_request
      assert_equal [ "errors" ], response.parsed_body.keys
      assert_includes response.parsed_body["errors"].first, "tagged, diagnosing"
    end
  end

  test "service creation requires auth, returns a location, and ignores unpermitted attributes" do
    with_api_token do
      post "/api/v1/services",
        params: { service_catalog_item: { name: "Brake adjustment", price: "25.00", id: 999 } }.to_json,
        headers: authorization_headers

      assert_response :created
      assert_equal "application/json", response.media_type
      assert_match %r{\Ahttp://www\.example\.com/api/v1/services/\d+\z}, response.headers["Location"]
      assert_equal "Brake adjustment", response.parsed_body["name"]
      assert_not_equal 999, response.parsed_body["id"]
    end
  end

  test "empty service creation is a bad request and validation errors are unprocessable" do
    with_api_token do
      post "/api/v1/services", params: {}.to_json, headers: authorization_headers
      assert_response :bad_request
      assert_equal [ "errors" ], response.parsed_body.keys

      post "/api/v1/services", params: "{", headers: authorization_headers
      assert_response :bad_request
      assert_equal [ "errors" ], response.parsed_body.keys

      post "/api/v1/services",
        params: { service_catalog_item: { unrecognized: "value" } }.to_json,
        headers: authorization_headers
      assert_response :bad_request
      assert_equal [ "errors" ], response.parsed_body.keys

      post "/api/v1/services",
        params: { service_catalog_item: { name: "", price: "0" } }.to_json,
        headers: authorization_headers
      assert_response :unprocessable_entity
      assert_equal [ "errors" ], response.parsed_body.keys
      assert_not_empty response.parsed_body["errors"]
    end
  end

  test "missing resource ids return the common JSON error shape" do
    with_api_token do
      get "/api/v1/services/999999"
      assert_response :not_found
      assert_equal({ "errors" => [ "Record not found." ] }, response.parsed_body)

      get "/api/v1/repairs/999999", headers: authorization_headers
      assert_response :not_found
      assert_equal({ "errors" => [ "Record not found." ] }, response.parsed_body)
    end
  end

  private

  def authorization_headers
    {
      "Authorization" => "Bearer #{API_TOKEN}",
      "Content-Type" => "application/json"
    }
  end

  def with_api_token
    credentials = Rails.application.credentials
    original_dig = credentials.method(:dig)
    credentials.define_singleton_method(:dig) do |*keys|
      keys == [ :api, :token ] ? API_TOKEN : original_dig.call(*keys)
    end
    yield
  ensure
    credentials.define_singleton_method(:dig, original_dig) if credentials
  end
end
