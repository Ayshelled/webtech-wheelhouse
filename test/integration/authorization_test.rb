require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @owner_staff = Staff.create!(name: "Riley Owner", role: "Owner")
    @counter_staff = Staff.create!(name: "Casey Counter", role: "Counter staff")
    @mechanic_staff = Staff.create!(name: "Jordan Mechanic", role: "Mechanic")
    @other_mechanic_staff = Staff.create!(name: "Taylor Mechanic", role: "Mechanic")
    @owner = create_user("owner@example.test", :owner, @owner_staff)
    @counter = create_user("counter@example.test", :counter, @counter_staff)
    @mechanic = create_user("mechanic@example.test", :mechanic, @mechanic_staff)
    @other_mechanic = create_user("other-mechanic@example.test", :mechanic, @other_mechanic_staff)

    @customer = Customer.create!(name: "Alex Rider", phone: "555-0101")
    @bike = Bike.create!(
      customer: @customer,
      make: "Surly",
      model: "Straggler",
      serial_number: "AUTH-001"
    )
    @own_repair = create_repair(assigned_staff: @mechanic_staff)
    @other_repair = create_repair(assigned_staff: @other_mechanic_staff, serial_number: "AUTH-002")
    @line_item = RepairLineItem.create!(
      repair: @own_repair,
      service_catalog_item: ServiceCatalogItem.create!(name: "Tune-up", price: 85),
      price_charged: 80
    )
  end

  test "a mechanic's repair index and record pages use the same assigned-repair scope" do
    sign_in_as(@mechanic)

    get repairs_path

    assert_response :success
    assert_select "a[href='#{repair_path(@own_repair)}']"
    assert_select "a[href='#{repair_path(@other_repair)}']", count: 0

    get repair_path(@own_repair)
    assert_response :success

    get repair_path(@other_repair)
    assert_response :forbidden
    assert_select "h1", text: "You're not allowed to do that."

    get edit_repair_path(@other_repair)
    assert_response :forbidden
  end

  test "a mechanic without linked staff has no repairs" do
    unlinked_mechanic = create_user("unlinked@example.test", :mechanic)
    sign_in_as(unlinked_mechanic)

    get repairs_path

    assert_response :success
    assert_select "a[href='#{repair_path(@own_repair)}']", count: 0
    assert_select "a[href='#{repair_path(@other_repair)}']", count: 0
  end

  test "repair index query count stays constant as repairs grow for every role" do
    {
      owner: @owner,
      counter: @counter,
      mechanic: @mechanic
    }.each do |role, user|
      sign_in_as(user)
      initial_query_count = select_query_count(repairs_path)

      2.times do |index|
        create_repair(
          assigned_staff: user.staff || @mechanic_staff,
          serial_number: "AUTH-#{role}-#{index}"
        )
      end

      assert_equal initial_query_count, select_query_count(repairs_path), "#{role} role"
    end
  end

  test "a denied update renders 403 and does not change the repair" do
    sign_in_as(@mechanic)
    original_status = @other_repair.status

    patch repair_path(@other_repair), params: { repair: { status: "diagnosing" } }

    assert_response :forbidden
    assert_equal original_status, @other_repair.reload.status
  end

  test "only the owner can edit a handed-back repair and denied deletion preserves it" do
    handed_back_repair = create_repair(assigned_staff: @mechanic_staff, serial_number: "AUTH-CLOSED")
    handed_back_repair.update!(
      status: :picked_up,
      customer_approved: true,
      handed_back_at: Time.current
    )

    sign_in_as(@counter)
    get repair_path(handed_back_repair)
    assert_response :success
    get edit_repair_path(handed_back_repair)
    assert_response :forbidden
    assert_no_difference "Repair.count" do
      delete repair_path(handed_back_repair)
    end
    assert_response :forbidden
    assert Repair.exists?(handed_back_repair.id)

    sign_in_as(@mechanic)
    get repair_path(handed_back_repair)
    assert_response :success
    get edit_repair_path(handed_back_repair)
    assert_response :forbidden

    sign_in_as(@owner)
    get edit_repair_path(handed_back_repair)
    assert_response :success
  end

  test "mechanics can change only allowed repair attributes" do
    sign_in_as(@mechanic)

    get edit_repair_path(@own_repair)

    assert_response :success
    assert_select 'select[name="repair[status]"]'
    assert_select "trix-editor"
    assert_select 'input[type="file"][name="repair[photos][]"]'
    assert_select 'select[name="repair[bike_id]"]', count: 0
    assert_select 'select[name="repair[assigned_staff_id]"]', count: 0
    assert_select 'input[name="repair[promised_on]"]', count: 0
    assert_select '[name^="repair[repair_line_items_attributes]"]', count: 0

    patch repair_path(@own_repair), params: {
      repair: {
        status: "diagnosing",
        diagnosis: "<p>Check the gears.</p>",
        photos: [ fixture_file_upload(Rails.root.join("db/seeds/red-bicycle.jpg"), "image/jpeg") ],
        assigned_staff_id: @other_mechanic_staff.id,
        promised_on: Date.current + 20,
        repair_line_items_attributes: {
          "0" => { id: @line_item.id, price_charged: "1.00" }
        }
      }
    }

    assert_redirected_to repair_path(@own_repair)
    @own_repair.reload
    assert_equal "diagnosing", @own_repair.status
    assert_includes @own_repair.diagnosis.to_plain_text, "Check the gears."
    assert_equal @mechanic_staff.id, @own_repair.assigned_staff_id
    assert_equal @line_item.price_charged, @line_item.reload.price_charged
    assert_equal 1, @own_repair.photos.count
  end

  test "counter can take in a repair and intake account comes from the session" do
    sign_in_as(@counter)

    assert_difference "Repair.count" do
      post repairs_path, params: {
        repair: {
          bike_id: @bike.id,
          intake_staff_id: @counter_staff.id,
          assigned_staff_id: @mechanic_staff.id,
          promised_on: Date.current + 3,
          status: "tagged",
          intake_user_id: @owner.id
        }
      }
    end

    assert_response :redirect
    created_repair = Repair.order(:id).last
    assert_equal @counter.id, created_repair.intake_user_id
  end

  test "visitors are redirected instead of receiving a forbidden page" do
    get customers_path

    assert_redirected_to new_session_path
    follow_redirect!
    assert_response :success
    assert_select "h1", text: "Sign in"
    assert_select "h1", text: "You're not allowed to do that.", count: 0
  end

  private

  def create_user(email, role, staff = nil)
    User.create!(
      email_address: email,
      password: "AuthorizationTest26!",
      staff: staff,
      role: role
    )
  end

  def create_repair(assigned_staff:, serial_number: "AUTH-001")
    bike = if serial_number == "AUTH-001"
      @bike
    else
      Bike.create!(
        customer: @customer,
        make: "Surly",
        model: "Straggler",
        serial_number: serial_number.to_s
      )
    end

    Repair.create!(
      bike: bike,
      intake_staff: @counter_staff,
      assigned_staff: assigned_staff,
      promised_on: Date.current + 5,
      status: :in_progress,
      customer_approved: true
    )
  end

  def select_query_count(path)
    count = 0
    ActiveRecord::Base.connection.clear_query_cache
    subscriber = lambda do |_name, _start, _finish, _id, payload|
      if payload[:sql].lstrip.start_with?("SELECT") && !payload[:cached] && payload[:name] != "SCHEMA"
        count += 1
      end
    end

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      get path
    end

    assert_response :success
    count
  end
end
