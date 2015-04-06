# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#

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
    user.total_balance.should == 0
  end
  
  it "adds PayPal funds to a user and checks its balance" do
    user = User.new(FactoryGirl.attributes_for(:user))
    Transaction.create do |t|
      t.user    = user
      t.amount  = 50
      t.state   = Transaction::STATE_FINAL
      t.kind    = Transaction::KIND_PAYPAL
      t.detail  = 8391 # reference to paypal
    end
    user.total_balance.should == 50
    a = Transaction.create do |t|
      t.user    = user
      t.amount  = 30
      t.state   = Transaction::STATE_FINAL
      t.kind    = Transaction::KIND_PAYPAL
      t.detail  = 4810
    end
    user.total_balance.should == 80
  end
end
