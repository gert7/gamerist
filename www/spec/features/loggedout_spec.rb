require 'spec_helper'

describe 'Logged out' do
  it 'welcomes the user' do
    visit '/'
    expect(page).to have_content('Win games for money')
  end

  it 'logs in the user and shows the sign out link', js: true do
    user = FactoryGirl.build(:user)
    visit '/'
    expect(page.find("#headbar_loggedin_name")).to have_content("Sign in")
    login_as(user)
    visit '/'
    expect(page.find("#headbar_loggedin_name")).to have_content("Sign out")
  end
  
  it 'logs in the user then logs out', js: true do
    user = FactoryGirl.create(:user)
    login_as(user)
    visit '/'
    click_button("I UNDERSTAND")
    click_link("Sign out")
    visit '/'
    expect(page.find("#headbar_loggedin_name")).to have_content("Sign in")
  end

  it 'shows guest currently available rooms' do
    visit '/rooms'
    expect(page.status_code).to be 200
  end
  
  it 'fails to access the new room form' do
    visit '/rooms/new'
    expect(page).to have_content "You need to sign in or sign up before continuing."
  end
end

