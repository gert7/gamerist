class Users::SessionsController < Devise::SessionsController
  def new
    super
  end
  
  def create
    super
    Usertrace.create(ipaddress: request.remote_ip, timestamp: Time.now, user_id: current_user.id)
  end
end
