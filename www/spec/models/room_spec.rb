require 'spec_helper'

describe Room do
  before(:each) do
  end

  describe "#make_room" do
    it "successfully creates a new room" do
      r = Room.create(game: "team fortress 2", map: "ctf_2fort", playercount: 8, wager: 5)
      expect(r.new_record?).to eq false
    end
    
    it "fails because the parameters are wrong" do
      r1 = Room.create(game: "team fooftress 2", map: "ctf_2fort", playercount: 8, wager: 5)
      expect(r1.new_record?).to eq true
      r2 = Room.create(game: "team fortress 2", map: "cp_2fort", playercount: 8, wager: 5)
      expect(r2.new_record?).to eq true
      r3 = Room.create(game: "team fortress 2", map: "ctf_2fort", playercount: 9, wager: 5)
      expect(r3.new_record?).to eq true
      r4 = Room.create(game: "team fortress 2", map: "ctf_2fort", playercount: 8, wager: -1)
      expect(r4.new_record?).to eq true
    end
    
    it "has valid rules struct" do
      r = Room.create(game: "team fortress 2", map: "ctf_2fort", playercount: 16, wager: 10)
      expect(r.new_record?).to eq false
      rj = r.srules
      expect(rj["game"]).to eq "team fortress 2"
      expect(rj["map"]).to eq "ctf_2fort"
      expect(rj["playercount"]).to eq 16
      expect(rj["wager"]).to eq 10
    end
  end
  
  describe "#update_room" do
  end
end

