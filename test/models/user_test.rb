require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "defaults to the least-privileged account role" do
    assert_equal "counter", User.new.role
  end

  test "requires a password of at least ten characters" do
    user = User.new(email_address: "short@example.com", password: "short")

    assert_not user.valid?
    assert_includes user.errors[:password], "must be at least 10 characters."
  end
end
