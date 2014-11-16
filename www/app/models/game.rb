# == Schema Information
#
# Table name: games
#
#  id         :integer          not null, primary key
#  prettyname :string(255)
#  enum       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

# Game identity, i.e. TF2, CS, Warsow
class Game < ActiveRecord::Base
	has_many :rooms
	has_many :maps

  def name
    self.prettyname
  end
end

