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
        Transaction.create do |t|
          t.state   = Transaction::STATE_FINAL,
          t.user    = user,
          t.kind    = Transaction::KIND_COUPON,
          t.detail  = 3080,
          t.amount  = 30
        end
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
end
