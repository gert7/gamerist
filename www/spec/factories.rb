FactoryGirl.define do
  factory :user do
    email { "useroni@mail.ch" }
    password "larkheid"
  end
  
  factory :paypal do
    amount 100.0
    subtotal 100.0
    tax 20.0
    state Paypal::STATE_CREATED
    sid "30004001020"
    redirect "https://www.sandbox.paypal.com/webscr?cmd=_express-checkout&token=EC-60U79048BN7719609"
    user { create(:user) }
  end

  factory :transaction do
  end
end
