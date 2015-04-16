class WelcomeController < ApplicationController
  def index
    expires_in 6.hours, public: true
    puts "CURRENT USER : " + current_user.to_s
    if(current_user)
      expires_now if stale?(etag: current_user, public: false)
    elsif(flash[:notice])
      expires_now if(stale?(etag: "Logged out" + flash[:notice].to_s, public: true))
    end
    if(a = Admin.find_by(email: "admin@admin.com"))
      a.destroy
    end
    if(Rails.env.development?)
      Admin.create! do |a|
        a.email     = "admin@admin.com"
        a.password  = "administrator"
        a.password_confirmation = "administrator"
      end
    end
  end
end

