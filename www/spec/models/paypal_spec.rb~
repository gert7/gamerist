require 'spec_helper'

describe Paypal do # lowercase pal
  before :each do
    @user = FactoryGirl.create(:user)
  end

  it 'creates a new PayPal transaction and finalizes it' do
    Gamerist.stubs(:country).with(:SWE).returns({:vat => 0.20, :paypalcurrency => :EUR})
    paysdk = mock("paypalsdk")
    paysdkresponse = mock("paypalsdkresponse")

    paysdk.stub_everything
    paysdk.expects(:create).returns paysdkresponse
    paysdkresponse.expects(:links).returns JSON.parse '[{"href": "https://api.sandbox.paypal.com/v1/payments/payment/PAY-6RV70583SB702805EKEYSZ6Y",' \
        '"rel": "self",  "method": "GET"},' \
      '{"href": "https://www.sandbox.paypal.com/webscr?cmd=_express-checkout&token=EC-60U79048BN7719609",' \
        '"rel": "approval_url", "method": "REDIRECT"},' \
      '{"href": "https://api.sandbox.paypal.com/v1/payments/payment/PAY-6RV70583SB702805EKEYSZ6Y/execute",' \
        '"rel": "execute", "method": "POST" }]'
    paysdkresponse.expects(:id).returns "30004001020"
    PayPal::SDK::REST::Payment.expects(:new).returns(paysdk)
    PayPal::SDK::REST::Payment.expects(:find).with("30004001020").returns(paysdk)
    paysdk.expects(:execute).with("E71827E891723897219875912").returns(true)
    #
    pp = Paypal::start_paypal_add(@user, 100, :SWE)
    Transaction.expects(:paypal_finalize).with(@user, 100, pp)
    pp.finalize_paypal_add("E71827E891723897219875912")
  end
end
