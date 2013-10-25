require "redis"

class WelcomeController < ApplicationController
  def index
    redis = Redis.new
	redis.publish("gamerist_node", "Eschelon")
  end
end
