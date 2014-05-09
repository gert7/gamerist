require 'spec_helper'

describe Paypal do # lowercase pal
  before :each do
    User.any_instance.stubs(:id).returns(42)
    @user = User.new
  end

  it 'creates a new PayPal transaction and finalizes it' do
    Transaction.expects(:paypal_finalize)
    Paypal.expects(:create)
    Gamerist.stubs(:country).with(:SWE).returns({:vat => 0.20, :paypalcurrency => :EUR})
    paysdk = mock("paypalsdk")
    paysdkresponse = mock("paypalsdkresponse")

    paysdk.stub_everything
    paysdk.expects(:create).returns paysdkresponse
    paysdkresponse.expects(:links).returns([
    {
      "href" => "https://api.sandbox.paypal.com/v1/payments/payment/PAY-17S8410768582940NKEE66EQ",
      "rel" => "self",
      "method" => "GET"
    }
  ])
    PayPal::SDK::REST::Payment.expects(:new).returns(paysdk)
    PayPal::SDK::REST::Payment.expects(:find)
    #
    pp = Paypal::start_paypal_add(@user, 100, :SWE)
    Paypal::finalize_paypal_add(pp.sid)
  end
end