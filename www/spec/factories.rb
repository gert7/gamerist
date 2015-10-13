FactoryGirl.define do
  factory :steamid do
    steamid "4718236478123"
  end

  factory :user do
    email "useroni@mail.ch"
    password "larkheid"
    association :steamid, factory: :steamid
  end
  
  factory :player1, class: :user do
    email "bonk@bonkmail.se"
    password "faradays"
    association :steamid, factory: :steamid
  end
  
  factory :player2, class: :user do
    email "fire@firemail.no"
    password "triangles"
    association :steamid, factory: :steamid
  end
  
  factory :player3, class: :user do
    email "brine@brinemail.dk"
    password "cubicles"
    association :steamid, factory: :steamid
  end
  
  factory :player4, class: :user do
    email "fetch@fetchmail.de"
    password "quadruples"
    association :steamid, factory: :steamid
  end
  
  factory :player5, class: :user do
    email "stoip@stopi.com"
    password "virriburus"
    association :steamid, factory: :steamid
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
  
  factory :room do
    game "team fortress 2"
    map "ctf_2fort"
    playercount "4"
    wager "5"
    server_region "Europe"
  end
  
  factory :room2, class: :room do
    game "team fortress 2"
    map "cp_dustbowl"
    playercount "8"
    wager "5"
  end
end
