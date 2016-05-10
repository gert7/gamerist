# == Schema Information
#
# Table name: accounts
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  countrycode   :string
#  nickname      :string
#  dob           :date
#  firstname     :string
#  lastname      :string
#  paypaladdress :string
#  created_at    :datetime
#  updated_at    :datetime
#

class Account < ActiveRecord::Base
  belongs_to :user, inverse_of: :account
end
