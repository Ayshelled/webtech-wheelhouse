require "test_helper"

class BrowserCrudTest < ActionDispatch::IntegrationTest
  setup do
    @customer = Customer.create!(name: "Casey Example", phone: "555-0100")
    @staff = Staff.create!(name: "Morgan Mechanic", role: "Mechanic")
    @bike = Bike.create!(customer: @customer, make: "Trek", model: "FX", serial_number: "TEST-001")
    @service = ServiceCatalogItem.create!(name: "Test tune-up", price: 80)
  end

  test "customer writes redirect, filter extra fields, and consume flash" do
    post customers_path, params: { customer: { name: "Jordan Example", phone: "555-0101", unexpected: "discarded" } }

    customer = Customer.find_by!(name: "Jordan Example")
    assert_redirected_to customer_path(customer)
    assert_equal "555-0101", customer.phone
    follow_redirect!
    assert_response :success
    assert_select ".alert-success", text: /Jordan Example/

    get customer_path(customer)
    assert_select ".alert", count: 0

    patch customer_path(customer), params: { customer: { name: "Jordan Updated", phone: "555-0102" } }
    assert_redirected_to customer_path(customer)
    assert_equal "Jordan Updated", customer.reload.name

    delete customer_path(customer)
    assert_response :see_other
    assert_redirected_to customers_path
  end

  test "missing resource parameters return bad request" do
    post customers_path, params: { name: "No resource root" }

    assert_response :bad_request
  end

  test "invalid customer creation renders the submitted values with errors" do
    assert_no_difference "Customer.count" do
      post customers_path, params: { customer: { name: "Preserved Name", phone: "" } }
    end

    assert_response :unprocessable_entity
    assert_select 'input[name="customer[name]"][value="Preserved Name"]'
    assert_select 'input[name="customer[phone]"].is-invalid'
    assert_select ".alert-danger li", text: /phone/
  end

  test "invalid customer update stays on the member URL and keeps submitted values" do
    patch customer_path(@customer), params: { customer: { name: "Attempted Name", phone: "" } }

    assert_response :unprocessable_entity
    assert_equal customer_path(@customer), request.path
    assert_select 'input[name="customer[name]"][value="Attempted Name"]'
    assert_equal "Casey Example", @customer.reload.name
  end

  test "repair saves selected lines and ignores unused lines" do
    assert_difference "Repair.count" do
      assert_difference "RepairLineItem.count" do
        post repairs_path, params: {
          repair: {
            bike_id: @bike.id,
            intake_staff_id: @staff.id,
            assigned_staff_id: "",
            promised_on: Date.tomorrow,
            status: "tagged",
            customer_approved: "",
            approved_at: "",
            quoted_at: "",
            handed_back_at: "",
            repair_line_items_attributes: {
              "0" => { service_catalog_item_id: @service.id, price_charged: "52.50" },
              "1" => { service_catalog_item_id: "", price_charged: "0" }
            }
          }
        }
      end
    end

    repair = Repair.order(:id).last
    assert_redirected_to repair_path(repair)
    assert_equal BigDecimal("52.50"), repair.repair_line_items.first.price_charged
    assert_nil repair.assigned_staff_id
  end

  test "zero-priced repair line is refused with field errors and empty slots" do
    assert_no_difference [ "Repair.count", "RepairLineItem.count" ] do
      post repairs_path, params: {
        repair: {
          bike_id: @bike.id,
          intake_staff_id: @staff.id,
          promised_on: Date.tomorrow,
          status: "tagged",
          repair_line_items_attributes: {
            "0" => { service_catalog_item_id: @service.id, price_charged: "0" }
          }
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".alert-danger", text: /price charged must be greater than 0/i
    assert_select 'input[name^="repair[repair_line_items_attributes]"][name$="[price_charged]"]', minimum: 3
    assert_select ".invalid-feedback", text: /price charged must be greater than 0/i
  end

  test "customer with a bike is not deleted and receives the model reason" do
    delete customer_path(@customer)

    assert_redirected_to customer_path(@customer)
    follow_redirect!
    assert_select ".alert-danger", text: /bikes/i
    assert Customer.exists?(@customer.id)
  end

  test "charged service is not deleted and receives the model reason" do
    repair = Repair.create!(bike: @bike, intake_staff: @staff, promised_on: Date.tomorrow, status: :tagged)
    RepairLineItem.create!(repair: repair, service_catalog_item: @service, price_charged: 80)

    delete service_catalog_item_path(@service)

    assert_redirected_to service_catalog_item_path(@service)
    follow_redirect!
    assert_select ".alert-danger", text: /repair line items/i
    assert ServiceCatalogItem.exists?(@service.id)
  end

  test "repair update removes an existing nested service line" do
    repair = Repair.create!(bike: @bike, intake_staff: @staff, promised_on: Date.tomorrow, status: :tagged)
    line_item = RepairLineItem.create!(repair: repair, service_catalog_item: @service, price_charged: 80)

    assert_difference "RepairLineItem.count", -1 do
      patch repair_path(repair), params: {
        repair: {
          bike_id: @bike.id,
          intake_staff_id: @staff.id,
          assigned_staff_id: "",
          promised_on: Date.tomorrow,
          status: "tagged",
          customer_approved: "",
          approved_at: "",
          quoted_at: "",
          handed_back_at: "",
          repair_line_items_attributes: {
            "0" => { id: line_item.id, service_catalog_item_id: @service.id, price_charged: "80", _destroy: "1" }
          }
        }
      }
    end

    assert_redirected_to repair_path(repair)
    assert_not RepairLineItem.exists?(line_item.id)
  end

  test "destroy of a record that does not exist returns not found" do
    delete customer_path("missing")

    assert_response :not_found
  end

  test "all resource indexes, forms, and detail pages render" do
    repair = Repair.create!(bike: @bike, intake_staff: @staff, promised_on: Date.tomorrow, status: :tagged)
    resources = [
      [ customers_path, new_customer_path, edit_customer_path(@customer), customer_path(@customer) ],
      [ bikes_path, new_bike_path, edit_bike_path(@bike), bike_path(@bike) ],
      [ repairs_path, new_repair_path, edit_repair_path(repair), repair_path(repair) ],
      [ service_catalog_items_path, new_service_catalog_item_path, edit_service_catalog_item_path(@service), service_catalog_item_path(@service) ],
      [ staffs_path, new_staff_path, edit_staff_path(@staff), staff_path(@staff) ]
    ]

    resources.flatten.each do |path|
      get path
      assert_response :success, "Expected #{path} to render"
    end
  end

  test "deleting a bike cascades through its repairs and service lines" do
    repair = Repair.create!(bike: @bike, intake_staff: @staff, promised_on: Date.tomorrow, status: :tagged)
    line_item = RepairLineItem.create!(repair: repair, service_catalog_item: @service, price_charged: 80)

    assert_difference [ "Bike.count", "Repair.count", "RepairLineItem.count" ], -1 do
      delete bike_path(@bike)
    end

    assert_response :see_other
    assert_redirected_to bikes_path
    assert_not RepairLineItem.exists?(line_item.id)
  end
end
