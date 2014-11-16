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

  
end
