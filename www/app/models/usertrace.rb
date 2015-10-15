class Usertrace < ActiveRecord::Base
  belongs_to :user, inverse_of: :usertraces
end
