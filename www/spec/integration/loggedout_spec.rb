require 'spec_helper'

include Warden::Test::Helpers
Warden.test_mode!

describe 'Logged out' do
  after(:each) do
    Warden.test_reset!
  end

  it 'welcomes the user' do
    visit '/'
    page.should have_content('Win games for money')
  end

  it 'logs in the user and shows the sign out link' do
    @user = FactoryGirl.build(:user)
    visit '/'
    page.find("#headbar_loggedin_name").should have_content("Sign in")
    login_as(@user)
    visit '/'
    page.find("#headbar_loggedin_name").should have_content("Sign out")
  end
end

