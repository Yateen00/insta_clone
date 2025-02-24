class UserMailer < ApplicationMailer
  default from: "no-reply@insta_clone.com"

  def welcome_email(user)
    @user = user
    @url = "https://insta-clone-r4eg.onrender.com"
    mail(to: @user.email, subject: "Welcome to Insta Clone")
  end
end
