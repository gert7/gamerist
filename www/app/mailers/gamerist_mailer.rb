class GameristMailer < ActionMailer::Base
  default from: "reset@gamerist.co"
  
  def welcome_email(email)
    mail(to: email, subject: 'Welcome to My Awesome Site')
  end
end
