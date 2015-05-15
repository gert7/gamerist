# == Schema Information
#
# Table name: steamids
#
#  id         :integer          not null, primary key
#  steamid    :string(255)
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

class Steamid < ActiveRecord::Base
  belongs_to :user, inverse_of: :steamid
  
  def to_s
    self.steamid
  end
  
  def self.attach_by_steam_callback(usr, req)
    stid = req[:extra][:raw_info][:steamid]
    
    err = "User not logged in!" unless usr
    err = "No Steam ID found!" unless (err or stid)
    
    unless err
      Steamid.where(user: usr).first_or_create do |t|
        t.user    = usr
        t.steamid = stid
      end
    end
    
    err
  end
end
