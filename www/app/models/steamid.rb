# == Schema Information
#
# Table name: steamids
#
#  id         :integer          not null, primary key
#  steamid    :string
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

class Steamid < ActiveRecord::Base
  belongs_to :user, inverse_of: :steamid
  
  class UserNotLoggedIn < Exception
  end
  
  class SteamIDNotInRequest < Exception
  end
  
  class SteamIDNotNumeric < Exception
  end
  
  def to_s
    self.steamid
  end
  
  def self.attach_by_steam_callback(usr, req)
    begin
      stid = req[:extra][:raw_info][:steamid]
    rescue NoMethodError
      raise SteamIDNotInRequest
    end
    
    raise UserNotLoggedIn unless usr
    raise SteamIDNotInRequest unless stid
    raise SteamIDNotNumeric unless stid.match(/^\d+$/)

    Steamid.where(user: usr).first_or_create do |t|
      t.user    = usr
      t.steamid = stid
    end
  end
end
