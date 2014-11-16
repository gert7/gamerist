# == Schema Information
#
# Table name: maps
#
#  id         :integer          not null, primary key
#  prefix     :string(255)
#  name       :string(255)
#  game_id    :integer
#  created_at :datetime
#  updated_at :datetime
#

class Map < ActiveRecord::Base
	belongs_to :game
end
