# == Schema Information
#
# Table name: rulesets
#
#  id          :integer          not null, primary key
#  map_id      :integer
#  playercount :integer
#  created_at  :datetime
#  updated_at  :datetime
#

class Ruleset < ActiveRecord::Base
	has_many :rooms
	belongs_to :game
end
