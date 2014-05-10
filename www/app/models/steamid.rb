class Steamid < ActiveRecord::Base
  belongs_to :user, inverse_of: :steamid

  
end
