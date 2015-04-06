require 'spec_helper'

describe Room do
  before(:each) do
  end

  describe "#make_room" do
    it "successfully creates a new room" do
      r = Room.make_room("team fortress 2", "ctf_2fort", 16, 5)
      expect(r.new_record?).to eq false
    end
    
    it "fails because the parameters are wrong" do
      r1 = Room.make_room("team fooftress 2", "ctf_2fort", 8, 5)
      expect(r1.new_record?).to eq true
      r2 = Room.make_room("team fortress 2", "cp_2fort", 8, 5)
      expect(r2.new_record?).to eq true
      r3 = Room.make_room("team fortress 2", "ctf_2fort", 9, 5)
      expect(r3.new_record?).to eq true
      r4 = Room.make_room("team fortress 2", "ctf_2fort", 8, -2)
      expect(r4.new_record?).to eq true
    end
    
    it "has valid rules struct" do
      r = Room.make_room("team fortress 2", "ctf_2fort", 16, 10)
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

