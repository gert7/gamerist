require 'spec_helper'

describe Steamid do
  describe "#attach_by_steam_callback" do
    it "adds the steamid via omniauth callback" do
      user = FactoryGirl.create(:user)
      login_as(user)
      Steamid.attach_by_steam_callback(user, extra: { raw_info: { steamid: "V87A8N97398C441" }})
      expect(Steamid.find_by(user_id: user.id).to_s).to eq "V87A8N97398C441"
    end
    
    it "fails without a user" do
      err = Steamid.attach_by_steam_callback(nil, extra: { raw_info: { steamid: "V87A8N97398C441" }})
      expect(err).not_to eq nil
    end
    
    it "fails without a steamid" do
      user = FactoryGirl.create(:user)
      login_as(user)
      expect {
        Steamid.attach_by_steam_callback(user, nil)
      }.to raise_error(NoMethodError)
    end
  end
end
