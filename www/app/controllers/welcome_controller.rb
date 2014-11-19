class WelcomeController < ApplicationController
  def index
    Admin.destroy_all
    Admin.create! do |a|
      a.email     = "admin@admin.com"
      a.password  = "administrator"
      a.password_confirmation = "administrator"
    end
    10000.times do || YoloWorker.perform_async("YEllow") end
  end
end

