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

  test "repair updates append intake photos and do not change them when no file is selected" do
    repair = Repair.create!(bike: @bike, intake_staff: @staff, promised_on: Date.tomorrow, status: :tagged)
    first_upload = fixture_file_upload(Rails.root.join("db/seeds/red-bicycle.jpg"), "image/jpeg")
    repair.photos.attach(first_upload)
    first_attachment_id = repair.photos.attachments.first.id

    patch repair_path(repair), params: {
      repair: {
        bike_id: @bike.id,
        intake_staff_id: @staff.id,
        promised_on: Date.tomorrow,
        status: "diagnosing"
      }
    }

    assert_redirected_to repair_path(repair)
    assert_equal [ first_attachment_id ], repair.reload.photos.attachments.map(&:id)

    second_upload = fixture_file_upload(Rails.root.join("db/seeds/vintage-bicycles.jpg"), "image/jpeg")
    patch repair_path(repair), params: {
      repair: {
        bike_id: @bike.id,
        intake_staff_id: @staff.id,
        promised_on: Date.tomorrow,
        status: "diagnosing",
        photos: [ second_upload ]
      }
    }

    assert_redirected_to repair_path(repair)
    assert_equal 2, repair.reload.photos.attachments.count

    attachment = repair.photos.attachments.find { |photo| photo.id != first_attachment_id }
    assert_difference [ "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ], -1 do
      delete photo_repair_path(repair, photo_id: attachment.id)
    end
    assert_response :see_other
    assert_equal [ first_attachment_id ], repair.reload.photos.attachments.map(&:id)
  end

  test "mixed invalid photo uploads are rejected without attaching any file" do
    repair = Repair.create!(bike: @bike, intake_staff: @staff, promised_on: Date.tomorrow, status: :tagged)
    original_upload = fixture_file_upload(Rails.root.join("db/seeds/red-bicycle.jpg"), "image/jpeg")
    repair.photos.attach(original_upload)
    original_attachment_id = repair.photos.attachments.first.id
    valid_upload = fixture_file_upload(Rails.root.join("db/seeds/vintage-bicycles.jpg"), "image/jpeg")
    invalid_upload = ActionDispatch::Http::UploadedFile.new(
      tempfile: StringIO.new("%PDF-1.4\n"),
      filename: "service-manual.pdf",
      type: "application/pdf"
    )

    assert_no_difference [ "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ] do
      patch repair_path(repair), params: {
        repair: {
          bike_id: @bike.id,
          intake_staff_id: @staff.id,
          promised_on: Date.tomorrow,
          status: "diagnosing",
          photos: [ valid_upload, invalid_upload ]
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", text: /service-manual\.pdf.*JPEG or PNG/
    assert_select 'select[name="repair[status]"] option[selected]', text: "Diagnosing"
    assert_equal [ original_attachment_id ], repair.reload.photos.attachments.map(&:id)
  end

  test "oversized intake photos are rejected with a filename and size message" do
    repair = Repair.create!(bike: @bike, intake_staff: @staff, promised_on: Date.tomorrow, status: :tagged)
    tempfile = Tempfile.new([ "oversized-photo", ".jpg" ])
    tempfile.binmode
    tempfile.write(File.binread(Rails.root.join("db/seeds/red-bicycle.jpg")))
    tempfile.write("\0" * 5.megabytes)
    tempfile.rewind
    upload = Rack::Test::UploadedFile.new(
      tempfile.path,
      "image/jpeg",
      original_filename: "oversized-intake.jpg"
    )

    assert_no_difference [ "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ] do
      patch repair_path(repair), params: {
        repair: {
          bike_id: @bike.id,
          intake_staff_id: @staff.id,
          promised_on: Date.tomorrow,
          status: "tagged",
          photos: [ upload ]
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", text: /oversized-intake\.jpg.*no larger than 5 MB/
  ensure
    tempfile&.close!
  end

  test "diagnosis HTML is rendered through Action Text without executable markup" do
    repair = Repair.create!(bike: @bike, intake_staff: @staff, promised_on: Date.tomorrow, status: :tagged)
    repair.diagnosis = '<p>Check the chain</p><script>alert("unsafe")</script><img src="x" onerror="alert(1)">'
    repair.save!

    get repair_path(repair)

    assert_response :success
    assert_select ".trix-content script", count: 0
    assert_select ".trix-content img[onerror]", count: 0

    get repairs_path
    assert_response :success
    assert_select ".repair-diagnosis", text: /Check the chain/
  end

  test "destroying a repair removes its photo and rich text records" do
    repair = Repair.create!(bike: @bike, intake_staff: @staff, promised_on: Date.tomorrow, status: :tagged)
    repair.diagnosis = "<strong>Check the chain</strong>"
    repair.save!
    repair.photos.attach(fixture_file_upload(Rails.root.join("db/seeds/red-bicycle.jpg"), "image/jpeg"))

    assert_difference [
      "Repair.count",
      "ActiveStorage::Attachment.count",
      "ActionText::RichText.count"
    ], -1 do
      delete repair_path(repair)
    end
    assert_response :see_other
    assert_not ActiveStorage::Attachment.exists?(record: repair)
    assert_not ActionText::RichText.exists?(record: repair)
  end

  test "repair index, bike, and detail pages keep their select count fixed as attachments grow" do
    repair = Repair.create!(bike: @bike, intake_staff: @staff, promised_on: Date.tomorrow, status: :tagged)
    repair.photos.attach(fixture_file_upload(Rails.root.join("db/seeds/red-bicycle.jpg"), "image/jpeg"))

    index_queries_before = count_select_queries(repairs_path)
    5.times do |index|
      extra_repair = Repair.create!(
        bike: @bike,
        intake_staff: @staff,
        promised_on: Date.tomorrow + index + 1,
        status: :tagged
      )
      extra_repair.photos.attach(fixture_file_upload(Rails.root.join("db/seeds/vintage-bicycles.jpg"), "image/jpeg"))
    end
    assert_equal index_queries_before, count_select_queries(repairs_path)

    bike_queries_before = count_select_queries(bike_path(@bike))
    5.times do |index|
      extra_repair = Repair.create!(
        bike: @bike,
        intake_staff: @staff,
        promised_on: Date.tomorrow + index + 10,
        status: :tagged
      )
      extra_repair.photos.attach(fixture_file_upload(Rails.root.join("db/seeds/damaged-bicycle.jpg"), "image/jpeg"))
    end
    bike_queries_after = count_select_queries(bike_path(@bike))
    assert_equal bike_queries_before, bike_queries_after, @last_select_queries.join("\n")

    detail_queries_before = count_select_queries(repair_path(repair))
    3.times do
      repair.photos.attach(fixture_file_upload(Rails.root.join("db/seeds/vintage-bicycles.jpg"), "image/jpeg"))
    end
    assert_equal detail_queries_before, count_select_queries(repair_path(repair))
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

    get repair_path(repair)
    assert_select "p", text: "No intake photos have been added."
    assert_select "p", text: "No diagnosis has been written."
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

  private

  def count_select_queries(path)
    count = 0
    @last_select_queries = []
    ActiveRecord::Base.connection.clear_query_cache
    subscriber = lambda do |_name, _start, _finish, _id, payload|
      if payload[:sql].lstrip.start_with?("SELECT") && !payload[:cached] && payload[:name] != "SCHEMA"
        count += 1
        @last_select_queries << payload[:sql]
      end
    end

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      get path
    end

    assert_response :success
    count
  end
end
