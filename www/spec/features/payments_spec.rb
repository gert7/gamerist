require 'spec_helper'

describe 'Payments' do
  it 'allows the user to enter credit card details' do
    user = FactoryGirl.build(:user)
    login_as user
    visit '/paypals/new'
    click_link("Credit Card")
    expect(page).to have_content("Name")
    expect(page).to have_content("Expiration")
    expect(page).to have_content("CVV")
  end
end
