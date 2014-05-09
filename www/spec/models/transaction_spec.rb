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

  it 'creates a new wager' do
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
end
