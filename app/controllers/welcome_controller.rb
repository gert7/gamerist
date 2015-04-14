class WelcomeController < ApplicationController
  def index
    Admin.find(email: "admin@admin.com").destroy
    if(Rails.env.development?)
      Admin.create! do |a|
        a.email     = "admin@admin.com"
        a.password  = "administrator"
        a.password_confirmation = "administrator"
      end
    end
  end
end

