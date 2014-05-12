require 'spec_helper'

describe Paypal do
  describe "#start_paypal_add" do
    context "when PayPal accepts" do
      it "asks PayPal for a Payment object" do
        PayPal::SDK::REST::Payment.expects(:new).with {|b|
          
        }
      end
      it "returns a new Paypal model" do
      end
    end
  end
end
