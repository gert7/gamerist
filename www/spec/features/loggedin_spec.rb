require "spec_helper"

describe "logged in" do
  context 'creating a new room' do
    before {
      user = FactoryGirl.create(:user)
      Transaction.create(user: user, detail: 100, kind: Transaction::KIND_PAYPAL, state: Transaction::STATE_FINAL, amount: 50)
      login_as(user)#, :scope => :user, :run_callbacks => false)
      stats = {"game_count" => 2, "games" => [{"appid" => 240, "playtime_forever" => 318}, {"appid" => 440, "playtime_forever" => 129}]}
      user.save_game_stats(stats)

      visit '/rooms/new'
      expect(page.find("#headbar_loggedin_name")).to have_content("Sign out")
      #choose('room_game_team_fortress_2', visible: false)
      find("label[for=room_playercount_8]").click
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
    
    it 'joins a team, then leaves it', js: true do
      click_on("Join Blu Team")
      click_on("Leave Room")
      expect(page).to have_content("Join Blu Team")
      expect(Room.last.srules["players"].count.to_i).to eq 0
    end
  end
  
  context 'joining another room' do
    before {
      user = FactoryGirl.create(:user)
      Transaction.create(user: user, detail: 10, kind: Transaction::KIND_PAYPAL, state: Transaction::STATE_FINAL, amount: 10)
      login_as(user)
      stats = {"game_count" => 2, "games" => [{"appid" => 240, "playtime_forever" => 318}, {"appid" => 440, "playtime_forever" => 129}]}
      user.save_game_stats(stats)
    }
  
    it "doesn't show buttons for an off-region room", js: true do
      room = Room.create do |r|
        r.game = "team fortress 2"
        r.map  = "ctf_2fort"
        r.playercount = 8
        r.wager = 5
        r.server_region = "North America"
      end
      
      visit("/rooms/" + room.id.to_s)
      expect(page).to have_content("Game: team fortress 2")
      expect(page).not_to have_content("Join Blu Team")
      expect(page).not_to have_content("Leave Room")
    end
    
    it "doesn't allow you to create an overly expensive room", js: true do
      visit '/rooms/new'
      #choose('room_game_team_fortress_2', visible: false)
      find("label[for=room_playercount_8]").click
      fill_in('room[wager]', with: 15)
      select('ctf_2fort', from: "room[map]")
      click_on("Create Room")
      expect(page).not_to have_content("Game: team fortress 2")
    end
  end
end
