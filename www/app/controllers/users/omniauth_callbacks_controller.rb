class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def open_id
    User.attach_steam(env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "Steam"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.open:id_data"] = env["openid.ext1"]
      redirect_to new_user_registration_url
    end
  end
end
