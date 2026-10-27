class WelcomeMailer < ApplicationMailer
  def welcome
    @user = params[:user]
    mail subject: "Welcome to Wheelhouse", to: @user.email_address
  end
end
