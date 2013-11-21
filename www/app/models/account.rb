class Account < ActiveRecord::Base
  belongs_to :user, inverse_of: :account
end
