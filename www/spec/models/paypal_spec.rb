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
#  sid        :string
#  redirect   :string
#  created_at :datetime
#  updated_at :datetime
#  country    :text
#

require 'spec_helper'

describe Paypal do
  let(:user) { User.new(FactoryGirl.attributes_for(:user)) }
  
  describe "#start_paypal_add" do
    it "asks for a payment object" do
      pp = Paypal.start_paypal_add(user, 100, :GER)
      expect(pp.new_record?).to eq false
    end
  end
end

