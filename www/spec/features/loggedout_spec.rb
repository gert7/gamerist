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
    click_link("Sign out")
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
  
  it 'creates a new room', js: true do
    user = FactoryGirl.create(:user)
    login_as(user)#, :scope => :user, :run_callbacks => false)
    
    visit '/rooms/new'
    expect(page.find("#headbar_loggedin_name")).to have_content("Sign out")
    #choose('room_game_team_fortress_2', visible: false)
    find("label[for=room_playercount_16]").click
    fill_in('room[wager]', with: 20)
    select('ctf_2fort', from: "room[map]")
    click_on("Create Room")
    expect(page).to have_content("Room created: team fortress 2")
  end
end

