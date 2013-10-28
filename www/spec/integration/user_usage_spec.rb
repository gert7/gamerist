require 'spec_helper'
describe "home page" do
  include Devise::TestHelpers
  it "should see the user's username after logging in" do
    user = User.create!(:email => "useroni@mail.ch", :password => "boosklet")
    sign_in user
  end
end
