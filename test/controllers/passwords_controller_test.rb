require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "create for an unknown user redirects but sends no mail" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "reset link is invalid"
  end

  test "update" do
    token = @user.password_reset_token
    assert_changes -> { @user.reload.password_digest } do
      put password_path(token), params: {
        password: "NewWheelhouse26!",
        password_confirmation: "NewWheelhouse26!"
      }
      assert_redirected_to new_session_path
    end

    follow_redirect!
    assert_notice "Password has been reset"

    get edit_password_path(token)
    assert_redirected_to new_password_path
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "NoMatchPassword26!", password_confirmation: "NotTheSame26!" }
      assert_response :unprocessable_entity
    end
    assert_select ".invalid-feedback", text: /doesn't match/
  end

  test "update refuses a password shorter than the minimum" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "short", password_confirmation: "short" }
      assert_response :unprocessable_entity
    end
    assert_select ".invalid-feedback", text: /at least 10 characters/
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
