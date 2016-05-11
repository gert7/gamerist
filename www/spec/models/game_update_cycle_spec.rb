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
end
