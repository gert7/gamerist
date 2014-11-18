class ImaJob
  @queue = :imajobs
  def self.perform(y)
    File.open("pepsi.txt", "a") do |f|
      f.write(y + "\n")
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
  end

  def enqueue
    if request.xhr?
      Resque.enqueue_in(60, ImaJob, "yolo")
      render json: '{"seconds": 60}'
    end
  end
end
