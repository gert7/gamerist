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
  
  context 'creating a new room' do
    before {
      user = FactoryGirl.create(:user)
      Transaction.create(user: user, detail: 100, kind: Transaction::KIND_PAYPAL, state: Transaction::STATE_FINAL, amount: 50)
      login_as(user)#, :scope => :user, :run_callbacks => false)
      
      visit '/rooms/new'
      expect(page.find("#headbar_loggedin_name")).to have_content("Sign out")
      #choose('room_game_team_fortress_2', visible: false)
      find("label[for=room_playercount_16]").click
      fill_in('room[wager]', with: 20)
      select('ctf_2fort', from: "room[map]")
      click_on("Create Room")
    }
  
    it 'creates a new room', js: true do
      expect(page).to have_content("Game: team fortress 2")
    end
    
    it 'gives the room the correct wager', js: true do
      expect(page.find("#srules_roomwager")).to have_content("20")
    end
    
    it 'flags the user as ready via button', js: true do
      click_on("Join Red Team")
      click_on("Ready")
      expect(page.find("#srules_readylabel")).not_to have_content("Not Ready")
    end
  end
end

