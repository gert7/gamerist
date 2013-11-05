require 'spec_helper'

describe User do
  before :each do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:steam] = OmniAuth::AuthHash.new({
      :provider => 'steam',
      :uid => '76561198010202071'
    })
  end
  
  it 'attaches an Omniauth test Steam ID' do
    user = User.new(FactoryGirl.attributes_for(:user))
    user.attach_steam OmniAuth.config.mock_auth[:steam]
    
    user.steamid.should == Steamid.last
    user.steamid.user.id.should == user.id
    user.steamid.steamid.class.should be String
  end
  
  it "checks a new user's balance" do
    user = User.new(FactoryGirl.attributes_for(:user))
    user.get_balance.should == 0
  end
  
  it "adds transactions to a user", pending: true do
    user = User.new(FactoryGirl.attributes_for(:user))
  end
  
  it "fetches a Redis key" do
    user = User.new(FactoryGirl.attributes_for(:user))
    user.stubs(:id).returns(1)
    user.redis_usertable("ambienza").should == "user-1[ambienza]"
  end
end
