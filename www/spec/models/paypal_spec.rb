# == Schema Information
#
# Table name: paypals
#
#  id         :integer          not null, primary key
#  amount     :decimal(8, 2)
#  subtotal   :decimal(8, 2)
#  tax        :decimal(8, 2)
#  state      :integer
#  user_id    :integer
#  sid        :string(255)
#  redirect   :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

class MethHash < Hash
  def method_missing(a)
    self[a.to_s]
  end
  
  def method # sorry
    self["method"]
  end
end

describe Paypal do
  let(:user) { User.new(FactoryGirl.attributes_for(:user)) }
  let(:p) { mock("payment") }
  let(:redirlink) { "http://www.success.paypal.com" }

  before {
    User.any_instance.stubs(:cache_key).returns("po[2]")
  }

  shared_context "PayPal API allows request" do
    before {
      #p = mock("payment")
      p.stubs(:error).returns("Payment method failed!")
      p.stubs(:id).returns("E1222229")    
    }
  end

  shared_context "PayPal can find payment" do
    PayPal::SDK::REST::Payment.stubs(:find).with do |e| e == "ASDGAF" end.returns p
  end

  shared_context "PayPal allows creation" do
    include_context "PayPal API allows request"
    before {
      p.stubs(:create).returns(true)
      PayPal::SDK::REST::Payment.expects(:new).with() do |ph|
        ph[:intent] == "sale" or return false
        ph[:payer][:payment_method] == "paypal" or return false
        total = ph[:transactions][0][:amount][:total].to_d
        ph[:transactions][0][:amount][:details][:subtotal].to_d == total - ph[:transactions][0][:amount][:details][:tax].to_d
      end.returns(p)
      #PayPal::SDK::REST::Payment.stubs(:new).returns("11")
    }
  end

  shared_context "PayPal forbids creation" do
    include_context "PayPal API allows request"
    before {
      p.stubs(:create).returns(false)
      PayPal::SDK::REST::Payment.expects(:new).returns(p)
    }
  end

  describe "#start_paypal_add" do
    context "when PayPal is willing" do
      include_context "PayPal allows creation"
      before {
        Paypal.stubs(:get_redir).returns(redirlink)
      }
      it "asks PayPal for a Payment object" do
        Paypal::start_paypal_add(user, 100, :SWE)
      end
      it "returns a new Paypal model" do
        pp = Paypal::start_paypal_add(user, 100, :SWE)
        expect(pp.sid).to eq "E1222229"
      end
    end
    context "when PayPal is not willing" do
      include_context "PayPal forbids creation" do
        it "fails to create a Payment object" do
          expect { Paypal::start_paypal_add(user, 100, :SWE)}.to raise_error
        end
      end
    end
  end

  describe "#get_redir" do
    context "when hash is proper" do
      let(:h) { JSON.parse('{"links": [{"method": "REDIRECT", "href": "http://www.success.paypal.com"}]}', object_class: MethHash) }
      it "returns the correct link" do
        expect(Paypal::get_redir(h)).to eq redirlink
      end
    end
    context "when hash is invalid" do
    end
  end

  describe "#finalize_paypal_add" do
    context "when payment is new" do
      let(:payp) { FactoryGirl.create :paypal }
      before {
        PayPal::SDK::REST::Payment.expects(:find).returns(p)
        p.expects(:execute).with() do |pid| pid[:payer_id] == "EN-99991" end.returns true
      }
      it "saves the transaction" do
        expect(payp.finalize_paypal_add("EN-99991").class).to eq Transaction
      end
    end
    context "when payment is already done" do
    end
  end
end
