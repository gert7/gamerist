# == Schema Information
#
# Table name: accounts
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  countrycode   :string(255)
#  nickname      :string(255)
#  dob           :date
#  firstname     :string(255)
#  lastname      :string(255)
#  paypaladdress :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

class Account < ActiveRecord::Base
  belongs_to :user, inverse_of: :account
end
