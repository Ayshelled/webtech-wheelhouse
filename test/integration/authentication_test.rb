require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @staff = Staff.create!(name: "Avery Counter", role: "Counter staff")
    @user = User.create!(
      email_address: "avery@example.test",
      password: "AveryWheelhouse26!",
      staff: @staff,
      role: :counter
    )
  end

  test "closed pages redirect to sign in and public service pages remain open" do
    get repairs_path
    assert_redirected_to new_session_path

    get service_catalog_items_path
    assert_response :success
    assert_select "a", text: "Services"
    assert_select "a", text: "Sign in"
    assert_select "a", text: "Repairs", count: 0

    service = ServiceCatalogItem.create!(name: "Public tune-up", price: 85)
    get service_catalog_item_path(service)
    assert_response :success

    get new_service_catalog_item_path
    assert_redirected_to new_session_path
  end

  test "sign in returns to the originally requested page" do
    get customers_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "AveryWheelhouse26!" }

    assert_redirected_to customers_url
    set_cookie = Array(response.headers["Set-Cookie"]).join("; ")
    assert_match(/httponly/i, set_cookie)
    assert_match(/samesite=lax/i, set_cookie)

    follow_redirect!
    assert_response :success
    assert_select ".navbar-text", text: /Avery Counter \(Counter\)/
    assert_select 'form[action="/session"] input[name="_method"][value="delete"]'
  end

  test "wrong account and wrong password produce the same message" do
    post session_path, params: { email_address: "missing@example.test", password: "AveryWheelhouse26!" }
    follow_redirect!
    missing_email_message = css_select(".alert-danger").text

    post session_path, params: { email_address: @user.email_address, password: "wrong-password" }
    follow_redirect!
    wrong_password_message = css_select(".alert-danger").text

    assert_equal missing_email_message, wrong_password_message
  end

  test "sign out is a delete and closes the next request" do
    sign_in_as(@user)

    get session_path
    assert_response :not_found

    delete session_path
    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]

    get repairs_path
    assert_redirected_to new_session_path
  end

  test "signup ignores submitted role and staff and queues welcome mail" do
    assert_difference "User.count" do
      assert_enqueued_emails 1 do
        post sign_up_path, params: {
          user: {
            email_address: "NEW.Member@Example.Test",
            password: "NewMemberWheelhouse26!",
            password_confirmation: "NewMemberWheelhouse26!",
            role: "owner",
            staff_id: @staff.id
          }
        }
      end
    end

    user = User.find_by!(email_address: "new.member@example.test")
    assert_equal "counter", user.role
    assert_nil user.staff
    assert user.sessions.exists?
    assert_redirected_to root_path
  end

  test "invalid signup keeps email, shows errors, and queues no mail" do
    assert_no_difference "User.count" do
      assert_no_enqueued_emails do
        post sign_up_path, params: {
          user: {
            email_address: "bad.email",
            password: "short",
            password_confirmation: "short"
          }
        }
      end
    end

    assert_response :unprocessable_entity
    assert_select 'input[name="user[email_address]"][value="bad.email"]'
    assert_select 'input[name="user[password]"][value]', count: 0
    assert_select ".invalid-feedback", text: /at least 10 characters/
    assert_select ".invalid-feedback", text: /valid/
  end

  test "account email uniqueness is case insensitive in validation and the database" do
    duplicate = User.new(
      email_address: "AVERY@EXAMPLE.TEST",
      password: "DuplicateWheelhouse26!"
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:email_address].any?

    assert_raises ActiveRecord::RecordNotUnique do
      User.insert!({
        email_address: "AVERY@EXAMPLE.TEST",
        password_digest: "not-used",
        role: "counter",
        created_at: Time.current,
        updated_at: Time.current
      })
    end
  end

  test "staff with an account cannot be destroyed" do
    assert_not @staff.destroy
    assert_includes @staff.errors.full_messages.join, "user"
    assert Staff.exists?(@staff.id)
  end

  test "staff deletion refusal is shown on the staff page" do
    sign_in_as(@user)

    delete staff_path(@staff)

    assert_redirected_to staff_path(@staff)
    follow_redirect!
    assert_select ".alert-danger", text: /user/i
    assert Staff.exists?(@staff.id)
  end

  test "password mail is branded multipart and contains a full local reset link" do
    email = PasswordsMailer.reset(@user)

    assert_match(/Wheelhouse/i, email.subject)
    assert_equal 2, email.parts.size
    assert_match(%r{http://example\.com/passwords/}, email.text_part.body.to_s)
    assert_match(/Wheelhouse/, email.html_part.body.to_s)
  end

  test "welcome mail is multipart and links to sign in" do
    email = WelcomeMailer.with(user: @user).welcome

    assert_match(/Wheelhouse/, email.subject)
    assert_equal 2, email.parts.size
    assert_includes email.text_part.body.to_s, @user.email_address
    assert_match(%r{http://example\.com/session/new}, email.html_part.body.to_s)
  end
end
