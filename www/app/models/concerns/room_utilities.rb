# Room mixin for pure convenience functions
module RoomUtilities
  # Find the players array index of a player in the given ruleset
  # @param [Integer] pid the id of the User of this player
  # @param [Hash] mrules a version of srules
  # @return [Integer] The position of the player in the given ruleset's player list
  def fetch_player(pid, mrules)
    mrules["players"].find_index { |v| v["id"].to_i == pid }
  end
  
  def teamcounts(mrules)
    teams = [0, 0]
    mrules["players"].each do |v|
      if(v["team"] == 2)
        teams[0] += 1
      elsif(v["team"] == 3)
        teams[1] += 1
      end
    end
    return teams
  end
  
  def total_players(mrules)
    teams = self.teamcounts(mrules)
    return teams[0] + teams[1]
  end
end
