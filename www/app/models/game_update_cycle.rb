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
  STATE_NONE          = 1
  STATE_GAME_LOCKING  = 2
  STATE_FINISHED      = 4
  
  # for individual servers
  STATE_HANDLR_KNOWS = 4
  
  UPDATE_CHECK_TIMEOUT = 300
  
  def h_get(k)
    $redis.hget("GAMERIST_UPDATE_CYCLE", k)
  end
  
  def h_set(k, v)
    $redis.hset("GAMERIST_UPDATE_CYCLE", k, v)
  end
  
  def scan_tf2_news(response, timestamp_from = 0)
    response["appnews"]["newsitems"].each do |it|
      if((it["date"].to_i > timestamp_from) and (it["feedname"] == "steam_updates") and (it["title"].match(/Team Fortress 2.*[Uu]pdate [Rr]eleased/)))
        return true
      end
    end
    return false
  end
  
  def tf2_needs_updating?(timestamp_from = 0)
    if Rails.env.test?
      return $tf2_needs_updating_force
    end
    puts "Querying Steam API for TF2 update..."
    require 'open-uri'
    ru = open("http://api.steampowered.com/ISteamNews/GetNewsForApp/v0002/?appid=440&count=30&maxlength=12&format=json").read
    return scan_tf2_news(JSON.parse(ru), timestamp_from)
  end
  
  def get_state_tf2
    xti = h_get("tf2_state")
    xte = h_get("tf2_last_updated")
    return xti.to_i if (xti and xte)
    t_cycle, f_cycle = nil, nil
    GameUpdateCycle.transaction do
      t_cycle = GameUpdateCycle.where(game: "team fortress 2", state: STATE_GAME_LOCKING).last
      f_cycle = GameUpdateCycle.where(game: "team fortress 2", state: STATE_FINISHED).last
    end
    h_set("tf2_last_updated", f_cycle.updated_at.to_i) if f_cycle
    if t_cycle and t_cycle.state == STATE_GAME_LOCKING
      h_set("tf2_state", STATE_GAME_LOCKING)
      return STATE_GAME_LOCKING
    end
    return STATE_NONE
  end
  
  # Only run after get_state_tf2
  def get_last_updated_tf2
    return (h_get("tf2_last_updated").to_i or 0)
  end
  
  def cycle_part_tf2
    puts "Checking for TF2 updates..."
    xti = get_state_tf2
    if xti == STATE_NONE
      if tf2_needs_updating?(get_last_updated_tf2)
        puts "TF2 NEEDS UPDATING!!"
        h_set("tf2_state", STATE_GAME_LOCKING)
        GameUpdateCycle.create(game: "team fortress 2", state: STATE_GAME_LOCKING)
      end
    elsif xti == STATE_GAME_LOCKING
    end
  end
  
  def cycle_part_css
    
  end
  
  def astartcycle
    xt = h_get("timer_global")
    puts xt.to_i
    puts Time.now.to_i
    if xt and (xt.to_i > Time.now.to_i)
      return
    end
    cycle_part_tf2
    # cycle_part_css
    h_set("timer_global", Time.now.to_i + UPDATE_CHECK_TIMEOUT)
  end
  
  def check_allowed_tf2
    xt = get_state_tf2
  end
  
  def agis_id
    "0"
  end
  
  def self.start_cycle
    self.new.acall($redis, :astartcycle)
  end
  
  after_initialize do
    agis_defm0(:astartcycle)
  end
end

