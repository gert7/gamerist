require 'spec_helper'

describe User do
  it 'attaches a dummy Steam ID' do
    user = User.new(FactoryGirl.attributes_for(:user))
    user.attach_steam 'uid' => "4789237148925721"
    
    user.steamid.should == Steamid.last
    user.steamid.user.id.should == user.id
    user.steamid.steamid.should == "4789237148925721"
  end
end
