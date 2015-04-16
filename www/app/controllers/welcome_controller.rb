class WelcomeController < ApplicationController
  def index
    expires_in 6.hours, public: true
    if(current_user)
      expires_now if stale?(etag: current_user, public: false)
    elsif(flash[:notice])
      expires_now if(stale?(etag: "Logged out" + flash[:notice].to_s, public: true))
    end
  end
end

