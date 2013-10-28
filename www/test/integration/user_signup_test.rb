require 'test_helper'

class UserSignupTest < ActionDispatch::IntegrationTest
  test "sign up and log out" do
	print "Starting https"
    https!
	print "getting users sign up page"
    get "/users/sign_up"
	print "Testing success"
    assert_response :success
    print "posting sign up"
    post_via_redirect "/users/sign_up", email: "useroni@mail.ch", password: "alpacat2", password_confirmation: "alpacat2"
	print "checking user logged in"
    assert user_logged_in?
	print "checking redirect"
    assert_redirected_to "welcome/index"
  end
end
