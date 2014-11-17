class ImaJob
  @queue = :imajobs
  def self.perform(y)
    File.open("pepsi.txt", "w") do |f|
      f.write("yopio")
    end
  end
end

require 'resque'

class WelcomeController < ApplicationController
  def index
    Admin.destroy_all
    Admin.create! do |a|
      a.email     = "admin@admin.com"
      a.password  = "administrator"
      a.password_confirmation = "administrator"
    end
    Resque.enqueue(ImaJob, "yolo")
  end
end
