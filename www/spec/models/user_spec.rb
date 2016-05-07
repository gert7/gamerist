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
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  relevantgames          :text
#

require 'spec_helper'

describe User do
  it "checks a new user's balance" do
    user = User.new(FactoryGirl.attributes_for(:user))
    expect(user.total_balance).to eq(0)
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
    expect(user.total_balance).to eq(50)
    a = Transaction.create do |t|
      t.user    = user
      t.amount  = 30
      t.state   = Transaction::STATE_FINAL
      t.kind    = Transaction::KIND_PAYPAL
      t.detail  = 4810
    end
    expect(user.total_balance).to eq(80)
  end
  
  describe "#reserve!" do
    it "reserves the player" do
      user = User.new(FactoryGirl.attributes_for(:user))
      user.reserve! Transaction::KIND_PAYPAL, 193
      expect(user.is_reserved?).to eq true
    end
    it "reserves the player as a room" do
      user = User.create(FactoryGirl.attributes_for(:user))
      room = Room.create(FactoryGirl.attributes_for(:room))
      user.reserve! Transaction::KIND_ROOM, room.id
      expect(user.get_reservation.class).to eq Room
      expect(user.get_reservation.id).to eq room.id
    end
  end
  
  describe "#unreserve_from_room" do
    it "unreserves the player" do
      user = User.create(FactoryGirl.attributes_for(:user))
      room = Room.create(FactoryGirl.attributes_for(:room))
      user.reserve! Transaction::KIND_ROOM, room.id
      user.unreserve_from_room(room.id)
      expect(user.is_reserved?).to eq false
    end
  end
  
  describe "#steamapi_timeout" do
    it "adds a timeout in the future" do
      user = User.create(FactoryGirl.attributes_for(:user))
      user.steamapi_timeout(Time.now.to_i + 30)
      expect(user.steamapi_timeout).to eq false
    end
    
    it "times out properly" do
      user = User.create(FactoryGirl.attributes_for(:user))
      user.steamapi_timeout(Time.now.to_i - 30)
      expect(user.steamapi_timeout).to eq true
    end
  end
end

