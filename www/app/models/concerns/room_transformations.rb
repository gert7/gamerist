# Room mixin containing pure functions
module RoomTransformations
  # Removes the player from the given mrules if the room is public
  # @param [Integer] player_id ID of the given player's User
  # @param [Hash] mrules old version of srules
  # @return new version of srules
  def _remove_player!(player_id, mrules)
    pi = fetch_player(player_id, mrules)
    if(pi and
       self.is_public?)
      mrules["players"].delete_at(pi)
    end
    mrules
  end
  
  # Removes all players not in teams
  def remove_exo_players(mrules)
    mrules["players"].delete_if {|value| value["team"].to_s == "0"}
    return mrules
  end

  def assign_to_team(pi, mrules, hash)
    wteam = hash["team"].to_i
    return mrules unless wteam
    mrules["players"][pi]["team"] = 0 if (wteam.to_s == "0")
    return mrules unless wteam.between?(2, 3)
    piteam = mrules["players"][pi]["team"]
    return mrules if piteam == wteam
    tcount  = self.teamcounts(mrules)
    perteam = mrules["playercount"] / 2
    perteam = 1 if (mrules["playercount"].to_i == 1) # TODO possibly remove?
    if wteam.between?(2, 3)
      if tcount[wteam - 2] < perteam
        mrules["players"][pi]["team"] = wteam
      else
        self.personal_messages << [1, "Team is not available!"]
      end
    else
      mrules["players"][pi]["team"] = 0
    end
    mrules["players"][pi]["wager"] = mrules["wager"]
    return mrules
  end
  
  def amend_player_ready(mrules, pi, hash)    
    mrules["players"][pi]["ready"] = "1" if(hash["ready"].to_s == "1")
    mrules["players"][pi]["ready"] = "0" if(hash["ready"].to_s == "0" or mrules["players"][pi]["team"].to_s == "0")
    mrules
  end
  
  def append_ip_address(pi, mrules, hash)
    return mrules unless hash["requestip"]
    mrules["players"][pi]["known_ips"] ||= Array.new
    kips = mrules["players"][pi]["known_ips"].to_set
    kips.add(hash["requestip"])
    mrules["players"][pi]["known_ips"] = kips.to_a
    mrules
  end
  
  def calc_wager(min, max, current)
    if(min and (min > current))
      return min
    elsif(max and (max < current))
      return max
    end
    current
  end
  
  # Sets the new wager for mrules.
  # If the lowest common wager for the room is
  # greater than the current, it shall be the new
  # shared wager.
  # If the highest common wager for the room is
  # lower than the current, it shall be the new
  # shared wager.
  #
  # @param [Hash] mrules old version of srules
  # @return [Hash] new version of srules
  def check_wager(mrules)
    wagers = mrules["players"].select{|v| v["team"].to_s != "0" and v["wager"].to_i > 0}.map {|v| v["wager"].to_i}
    min, max = wagers.min, wagers.max
    mrules["wager"] = calc_wager(min, max, mrules["wager"].to_i)
    mrules
  end
  
  # Add a remove notice to the given srules' chatbox
  # @param [Hash] mrules old version of mrules
  # @param [Integer] player_id the given player's User's id
  # @return [Hash] new version of srules
  def removenoticemsg(mrules, player_id)
    pi = fetch_player(player_id, mrules)
    return mrules unless pi
    add = "left:" + mrules["players"][pi]["steamname"] + " has left the room"
    mrules["messages"] ||= []
    if(mrules["messages"].count == 0)
      mrules["messages"] << {"message" => "TOP", "user_id" => 0, "addendum" => [add]}
    else
      mrules["messages"].last["addendum"] << add
    end
    mrules
  end
  
  def chat_addmsg(mrules, player_id, steamname, msg)
    mrules["messages"] ||= []
    ind = mrules["messages"].last["index"] if mrules["messages"].last
    ind ||= 0
    mrules["messages"] << {"index" => ind + 1, "message" => msg, "steamname" => steamname, "addendum" => []}
    mrules["messages"] = mrules["messages"][1..-1] if(mrules["messages"].count > Room::MESSAGES_STORE_MAX)
    mrules
  end
end
