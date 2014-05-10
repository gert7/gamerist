require 'spec_helper'

describe Transaction do
  before :each do
    User.any_instance.stubs(:id).returns(42)
    @user = User.new
  end

  it 'creates a new valid transaction by passing a block for the arguments' do
    tr = Transaction.new do |t|
      t.state   = Transaction::STATE_FINAL,
      t.user    = @user,
      t.kind    = Transaction::KIND_COUPON,
      t.detail  = 30, # coupon number 30
      t.amount  = 10
    end
    tr.save!
    tr.new_record?.should == false # is saved
  end

  it 'removes money from a user without money, and fails to do so' do
    tr = Transaction.new do |t|
      t.state   = Transaction::STATE_FINAL,
      t.user    = @user,
      t.kind    = Transaction::KIND_COUPON,
      t.detail  = 30, # coupon number 30
      t.amount  = -10
    end
    begin
      tr.save!
    rescue ActiveRecord::Rollback => e
    end
      tr.new_record?.should == true # is not saved
  end

  it 'adds unrealized funds to a new account, then spends them' do
    tr = Transaction.new do |t|
      t.state   = Transaction::STATE_FINAL,
      t.user    = @user,
      t.kind    = Transaction::KIND_ROOM,
      t.detail  = 30,
      t.amount  = 100
    end
    
  end
end
