# == Schema Information
#
# Table name: game_update_cycles
#
#  id         :integer          not null, primary key
#  game       :string
#  state      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require "agis"

class GameUpdateCycle < ActiveRecord::Base
  include Agis
  
  # for games
  STATE_DRAFT         = 1
  STATE_GAME_LOCKING  = 2
  STATE_HANDLR_RETURN = 16
  
  # for individual servers
  STATE_HANDLR_KNOWS = 4
  STATE_HANDLR_DONE  = 8
  
  def h_get(k)
    $redis.hget("GAMERIST_UPDATE_CYCLE", k)
  end
  
  def h_set(k, v)
    $redis.hset("GAMERIST_UPDATE_CYCLE", k, v)
  end
  
  def cycle_part_tf2
    xti = h_get("tf2_state")
    unless xti
      t_cycle = GameUpdateCycle.where(game: "team fortress 2").where.not(state: STATE_HANDLR_DONE).last
      xti = t_cycle.state
    end
    if xti == STATE_DRAFT
    elsif xti == STATE_GAME_LOCKING
    elsif xti == STATE_HANDLR_RETURN
    end
  end
  
  def cycle_part_css
    
  end
  
  def astartcycle
    xt = h_get("timer_global")
    if xt and (xt.to_i > Time.now.to_i)
      return
    end
    cycle_part_tf2
    cycle_part_css
    h_set("timer_global", Time.now.to_i)
  end
  
  def agis_id
    "0"
  end
  
  def self.start_cycle
    self.new.acall($redis, :astartcycle)
  end
  
  def initialize
    agis_defm0 :astartcycle
  end
end
