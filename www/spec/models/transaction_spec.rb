# == Schema Information
#
# Table name: transactions
#
#  id         :integer          not null, primary key
#  state      :integer
#  user_id    :integer
#  lastref    :integer
#  kind       :integer
#  detail     :integer
#  amount     :integer
#  balance_u  :integer
#  balance_r  :integer
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Transaction do
  let(:user) { FactoryGirl.create(:user) }
  let(:trac) { FactoryGirl.build(:transaction) }

  describe "#new" do
    context "when transaction is valid" do
      it 'creates a new transaction by block' do
        tr = Transaction.new do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_COUPON,
          t.detail  = 30, # coupon number 30
          t.amount  = 10
        end
        tr.save!
        expect(tr.new_record?).to eq false # is saved
      end

      it 'fails to withdraw from moneyless user' do
        tr = Transaction.new do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_COUPON,
          t.detail  = 30, # coupon number 30
          t.amount  = -10
        end
        begin
          tr.save!
        rescue; end
        expect(tr.new_record?).to eq true # is not saved
      end

      it 'allows consecutive realized funds' do
        Transaction.create(state: Transaction::STATE_FINAL, user: user, kind: Transaction::KIND_COUPON, detail: 3080, amount: 30)
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_COUPON,
          t.detail  = 3081,
          t.amount  = 30
        end
        expect(user.balance_unrealized).to eq 60
        expect(user.total_balance).to eq 60
      end

      it 'spends unrealized and realized funds' do
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_ROOM,
          t.detail  = 3080,
          t.amount  = 30
        end
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_COUPON,
          t.detail  = 411,
          t.amount  = 30
        end
        expect(user.total_balance).to eq 60
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_ROOM,
          t.detail  = 2001,
          t.amount  = (-40)
        end
        expect(user.balance_unrealized).to eq 0
        expect(user.balance_realized).to eq 20
      end
      
      it 'receives realized funds from PayPal' do
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_PAYPAL,
          t.detail  = 3022,
          t.amount  = 30
        end
        expect(user.balance_realized).to eq 30
        expect(user.balance_unrealized).to eq 0
      end
      
      it 'sends realized funds to PayPal' do
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_PAYPAL,
          t.detail  = 3022,
          t.amount  = 30
        end
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_PAYPAL,
          t.detail  = 3022,
          t.amount  = -30
        end
        expect(user.balance_realized).to eq 0
        expect(user.balance_unrealized).to eq 0
      end
      
      it "doesn't send unrealized funds to PayPal" do
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_COUPON,
          t.detail  = 3022,
          t.amount  = 30
        end
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_PAYPAL,
          t.detail  = 3022,
          t.amount  = -30
        end
        expect(user.balance_realized).to eq 0
        expect(user.balance_unrealized).to eq 30
      end
      
      it "specifically doesn't send unrealized funds to PayPal" do
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_COUPON,
          t.detail  = 3022,
          t.amount  = 30
        end
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_PAYPAL,
          t.detail  = 3023,
          t.amount  = 30
        end
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_PAYPAL,
          t.detail  = 3024,
          t.amount  = -30
        end
        expect(user.balance_realized).to eq 0
        expect(user.balance_unrealized).to eq 30
      end
      
      it "fails to withdraw while the user is reserved" do
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_PAYPAL,
          t.detail  = 3025,
          t.amount  = 30
        end
        r = FactoryGirl.create(:room)
        stats = {"game_count" => 2, "games" => [{"appid" => 240, "playtime_forever" => 318}, {"appid" => 440, "playtime_forever" => 129}]}
        user.save_game_stats(stats)
        r.amend_player! user, "team" => 2
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_PAYPAL,
          t.detail  = 3026,
          t.amount  = -15
        end
        expect(user.balance_realized).to eq 30
      end

      it "places and wins a wager" do
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_COUPON,
          t.detail  = 412,
          t.amount  = 10
        end
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_ROOM,
          t.detail  = 532,
          t.amount  = -10
        end
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_ROOM,
          t.detail  = 532,
          t.amount  = 20
        end
        expect(user.balance_unrealized).to eq 0
        expect(user.balance_realized).to eq 20
      end

      it "fails to overdraw" do
        tr = Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_ROOM,
          t.detail  = 1001,
          t.amount  = -10
        end
        tr.save!
        expect(tr.new_record?).to eq true
      end
    end
  end

  describe "#trickle_down_score" do
    it "trickles down from two sources" do
      trac.amount = -40
      trac.trickle_down_score(30, 40)
      expect([trac.balance_u, trac.balance_r]).to eq [0, 30]
    end
    it "trickles down from unrealized" do
      trac.amount = -20
      trac.trickle_down_score(30, 0)
      expect([trac.balance_u, trac.balance_r]).to eq [10, 0]
    end
    it "trickles down from realized" do
      trac.amount = -20
      trac.trickle_down_score(0, 30)
      expect([trac.balance_u, trac.balance_r]).to eq [0, 10]
    end
  end
  
  describe "#make_transaction" do
    it "creates a new transaction actorly" do
      tr = Transaction.make_transaction(state: Transaction::STATE_FINAL, user_id: user.id, kind: Transaction::KIND_COUPON, detail: 192, amount: 19)
      expect(user.total_balance).to eq 19
      expect(user.balance_unrealized).to eq 19
      expect(user.balance_realized).to eq 0
    end
  end
end
