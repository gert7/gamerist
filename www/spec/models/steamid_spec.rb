# == Schema Information
#
# Table name: steamids
#
#  id         :integer          not null, primary key
#  steamid    :string(255)
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Steamid do
  describe "#attach_by_steam_callback" do
    it "adds the steamid via omniauth callback" do
      user = User.new(FactoryGirl.attributes_for(:user))
      login_as(user)
      Steamid.attach_by_steam_callback(user, extra: { raw_info: { steamid: "4812374123423" }})
      expect(Steamid.find_by(user_id: user.id).to_s).to eq "4812374123423"
    end
    
    it "fails without a user" do
      expect {
        Steamid.attach_by_steam_callback(nil, extra: { raw_info: { steamid: "4812374123423" }})
      }.to raise_error(Steamid::UserNotLoggedIn)
    end
    
    it "fails without a steamid" do
      user = User.new(FactoryGirl.attributes_for(:user))
      login_as(user)
      expect {
        Steamid.attach_by_steam_callback(user, nil)
      }.to raise_error(Steamid::SteamIDNotInRequest)
    end
    
    it "fails if stid is not numeric" do
      user = User.new(FactoryGirl.attributes_for(:user))
      login_as(user)
      expect {
        Steamid.attach_by_steam_callback(user, extra: { raw_info: { steamid: "42897189423CD3" }})
      }.to raise_error(Steamid::SteamIDNotNumeric)
    end
  end
end
