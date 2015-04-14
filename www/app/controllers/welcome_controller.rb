class WelcomeController < ApplicationController
  def index
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

