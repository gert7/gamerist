require 'spec_helper'

describe Paypal do # lowercase pal
  let!(:user) { FactoryGirl.create(:user) }
  let(:payer_id) {"E71827E891723897219875912"}
  let!(:paypal_model) {FactoryGirl.create(:paypal)}

  before(:all) {
    Gamerist.stubs(:country).with(:SWE).returns({:vat => 0.20, :paypalcurrency => :EUR})
    paysdk = mock("paypalsdk")
    paysdkresponse = mock("paypalsdkresponse")

    paysdk.stub_everything
    paysdk.stubs(:create).returns paysdkresponse
    paysdkresponse.stubs(:links).returns JSON.parse '[{"href": "https://api.sandbox.paypal.com/v1/payments/payment/PAY-6RV70583SB702805EKEYSZ6Y",' \
      '"rel": "self",  "method": "GET"},' \
      '{"href": "https://www.sandbox.paypal.com/webscr?cmd=_express-checkout&token=EC-60U79048BN7719609",' \
      '"rel": "approval_url", "method": "REDIRECT"},' \
      '{"href": "https://api.sandbox.paypal.com/v1/payments/payment/PAY-6RV70583SB702805EKEYSZ6Y/execute",' \
      '"rel": "execute", "method": "POST" }]'
    paysdkresponse.stubs(:id).returns "30004001020"
    PayPal::SDK::REST::Payment.stubs(:new).returns(paysdk)
    PayPal::SDK::REST::Payment.stubs(:find).with("30004001020").returns(paysdk)
    paysdk.stubs(:execute).with(@payer_id).returns(true)
  }

  describe "#start_paypal_add" do
    context "PayPal is available" do
      it "makes a FINAL Transaction" do
        pp = Paypal::start_paypal_add(@user, 100, :SWE)
        Transaction.expects(:paypal_finalize).with(@user, 100, pp)
      end
    end
  end

  describe "#finalize_paypal_add" do
    context "PayPal is unavailable" do
      it 'finalizes transaction' do
        pp = FactoryGirl.create(:paypal)
        Transaction.expects(:paypal_finalize).with(pp.user, 100, pp)
        PayPal::SDK::REST::Payment.stubs(:find).returns false
        pp.finalize_paypal_add(@payer_id)
      end
    end
    context "Payer ID is correct" do
      it 'creates a new PayPal transaction and finalizes it' do    
        
      end
    end
    context "Payer ID is incorrect" do
      before {
        paysdk.stubs(:execute).with(@payer_id).returns(false) 
      }
      it 'creates a new PayPal transaction' do    
        pp = Paypal::start_paypal_add(@user, 100, :SWE)
        pp.finalize_paypal_add(@payer_id)
      end
    end
  end
end

