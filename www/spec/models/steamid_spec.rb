require 'spec_helper'

describe Steamid do
  describe "#attach_by_steam_callback" do
    before {
      @user = FactoryGirl.create(:user)
      login_as(@user)
    }
  
    it "adds the steamid via omniauth callback" do
      Steamid.attach_by_steam_callback(@user, extra: { raw_info: { steamid: "4812374123423" }})
      expect(Steamid.find_by(user_id: @user.id).to_s).to eq "4812374123423"
    end
    
    it "fails without a user" do
      expect {
        Steamid.attach_by_steam_callback(nil, extra: { raw_info: { steamid: "4812374123423" }})
      }.to raise_error(Steamid::UserNotLoggedIn)
    end
    
    it "fails without a steamid" do
      expect {
        Steamid.attach_by_steam_callback(@user, nil)
      }.to raise_error(Steamid::SteamIDNotInRequest)
    end
    
    it "fails if stid is not numeric" do
      expect {
        Steamid.attach_by_steam_callback(@user, extra: { raw_info: { steamid: "42897189423CD3" }})
      }.to raise_error(Steamid::SteamIDNotNumeric)
    end
  end
end
