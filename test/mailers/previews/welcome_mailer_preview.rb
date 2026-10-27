class WelcomeMailerPreview < ActionMailer::Preview
  def welcome
    WelcomeMailer.with(user: User.new(email_address: "new.member@example.com")).welcome
  end
end
