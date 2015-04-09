require 'spec_helper'

describe Room do
  let(:room) { FactoryGirl.create :room }
  let(:player1) { FactoryGirl.create :player1 }
  let(:player2) { FactoryGirl.create :player2 }
  let(:room2) { FactoryGirl.create :room2 }
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
  
  describe "#append_player!" do
    context "when players have money" do
      before {
        player1.stubs(:total_balance).returns 15
      }
      it "adds the player successfully" do
        room.append_player! player1
        expect(player1.is_reserved?).to eq true
        expect(room.srules["players"].count).to eq 1
        expect(room.srules["players"][0]["id"]).to eq player1.id
      end
      it "doesn't allow joining several rooms" do
        room.append_player! player1
        expect(room2.append_player! player1).to eq false
      end
    end
  end
end

