require 'spec_helper'

describe User do
  it 'attaches a dummy Steam ID' do
    user = User.new(FactoryGirl.attributes_for(:user))
    user.attach_steam 'uid' => "4789237148925721"
    
    user.steamid.should == Steamid.last
    user.steamid.user.id.should == user.id
    user.steamid.steamid.should == "4789237148925721"
  end
  
  it 'attaches an Omniauth test Steam ID' do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:steam] = OmniAuth::AuthHash.new({
      :provider => 'steam',
      :uid => '76561198010202071'
    )
  end
end
