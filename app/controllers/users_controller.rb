class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      WelcomeMailer.with(user: @user).welcome.deliver_later
      redirect_to after_authentication_url, notice: "Your account has been created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: %i[email_address password password_confirmation])
  end
end
