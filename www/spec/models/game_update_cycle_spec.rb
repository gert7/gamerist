require "spec_helper"

describe GameUpdateCycle do
  describe "#scan_tf2_news" do
    it "returns false when updates are not available" do
      data = {"appnews" => {"appid" => 440, "newsitems" => [{"gid" => "255953775625370861", "title" => "Valve VAC bans TF2 hack users, pro players caught", "url" => "http://store.steampowered.com/news/externalpost/pcgamer/255953775625370861", "is_external_url" => true, "author" => "", "contents" => "LM...", "feedlabel" => "PC Gamer", "date" => 1462118433, "feedname" => "pcgamer"}]}}
      expect(GameUpdateCycle.new.scan_tf2_news(data)).to eq false
    end
    
    it "returns true when updates are available" do
      data = {"appnews" => {"appid" => 440, "newsitems" => [{"gid" => "255953775625370861", "title" => "Team Fortress 2 Update Released", "url" => "http://store.steampowered.com/news/externalpost/pcgamer/255953775625370861", "is_external_url" => true, "author" => "", "contents" => "LM...", "feedlabel" => "PC Gamer", "date" => 1462118433, "feedname" => "steam_updates"}]}}
      expect(GameUpdateCycle.new.scan_tf2_news(data)).to eq true
    end
    
    it "returns false when updates are already installed" do
      data = {"appnews" => {"appid" => 440, "newsitems" => [{"gid" => "255953775625370861", "title" => "Team Fortress 2 Update Released", "url" => "http://store.steampowered.com/news/externalpost/pcgamer/255953775625370861", "is_external_url" => true, "author" => "", "contents" => "LM...", "feedlabel" => "PC Gamer", "date" => 1461865620, "feedname" => "steam_updates"}]}}
      expect(GameUpdateCycle.new.scan_tf2_news(data, Time.now.to_i)).to eq false
    end
  end
  
  describe "get_state_tf2" do
    it "finds the correct state and timeouts" do
      $tf2_needs_updating_force = false
      GameUpdateCycle.start_cycle
      expect(GameUpdateCycle.new.get_state_tf2).to eq GameUpdateCycle::STATE_NONE
      expect(GameUpdateCycle.new.get_last_updated_tf2).to eq 0
    end
    
    it "finds the correct state when updating" do
      $tf2_needs_updating_force = true
      GameUpdateCycle.start_cycle
      expect(GameUpdateCycle.new.get_state_tf2).to eq GameUpdateCycle::STATE_GAME_LOCKING
    end
    
    it "finds the correct state after previously updated" do
      $tf2_needs_updating_force = false
      gu = GameUpdateCycle.create(game: "team fortress 2", state: GameUpdateCycle::STATE_FINISHED)
      GameUpdateCycle.start_cycle
      expect(GameUpdateCycle.new.get_state_tf2).to eq GameUpdateCycle::STATE_NONE
      expect(GameUpdateCycle.new.get_last_updated_tf2.to_i).to eq gu.updated_at.to_i
    end
    
    it "recognizes currently updating" do
      $tf2_needs_updating_force = false
      gu = GameUpdateCycle.create(game: "team fortress 2", state: GameUpdateCycle::STATE_GAME_LOCKING)
      expect(GameUpdateCycle.new.get_state_tf2).to eq GameUpdateCycle::STATE_GAME_LOCKING
      expect(GameUpdateCycle.new.get_last_updated_tf2.to_i).to eq 0
    end
  end
end
