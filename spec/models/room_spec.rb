require 'spec_helper'

describe Room do
  let(:room) { FactoryGirl.create :room }
  let(:player1) { FactoryGirl.create :player1 }
  let(:player2) { FactoryGirl.create :player2 }
  let(:player3) { FactoryGirl.create :player3 }
  let(:player4) { FactoryGirl.create :player4 }
  let(:room2) { FactoryGirl.create :room2 }
  before(:each) do
  end

  shared_context("when players have money") do
    before {
      player1.stubs(:total_balance).returns 15
      player2.stubs(:total_balance).returns 15
      player3.stubs(:total_balance).returns 15
      player4.stubs(:total_balance).returns 15
    }
  end
  
  shared_context("when players have no money") do
    before {
      player1.stubs(:total_balance).returns 0
      player2.stubs(:total_balance).returns 0
      player3.stubs(:total_balance).returns 0
      player4.stubs(:total_balance).returns 0
    }
  end

  describe "#make_room" do
    it "successfully creates a new room" do
      r = Room.create(game: "team fortress 2", map: "ctf_2fort", playercount: 8, wager: 5, server: "trivulum")
      expect(r.new_record?).to eq false
    end
    
    it "successfully creates a room without server" do
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
      r5 = Room.create(game: "team fortress 2", map: "cp_dustbowl", playercount: 16, wager: 10, server: "flippum")
      expect(r5.new_record?).to eq true
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
      include_context "when players have money"
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
      it "reserves the player" do
        room.append_player! player1
        expect(player1.is_reserved?).to eq true
      end
      it "adds multiple players" do
        room.append_player! player1
        room.append_player! player2
        room.append_player! player3
        expect(room.srules["players"].count).to eq 3
      end
    end
    context "when players don't have money" do
      include_context "when players have no money"
      it "will not add the player" do
        room.append_player! player1
        expect(player1.is_reserved?).to eq false
        expect(room.srules["players"].count).to eq 0
      end
    end
    context "when there are several instances loaded" do
      include_context "when players have money"
      it "will not add the same player twice" do
        r1 = Room.find(room.id)
        r2 = Room.find(room.id)
        r1.append_player! player1
        r2.append_player! player1
        expect(r1.srules["players"].count).to eq 1
      end
      it "will affect the other instance" do
        r1 = Room.find(room.id)
        r2 = Room.find(room.id)
        r1.append_player! player1
        expect(r2.srules["players"].count).to eq 1
      end
    end
  end
  
  describe "#remove_player!" do
    it "removes the player from the room" do
      room.append_player! player1
      room.remove_player! player1
      expect(room.srules["players"].count).to eq 0
    end
    it "unreserves the player" do
      room.append_player! player1
      room.remove_player! player1
      expect(player1.is_reserved?).to eq false
    end
  end
  
  describe "#check_ready" do
    include_context "when players have money"
    context "when everyone is ready" do
      before {
        room.append_player! player1
        room.amend_player! player1, "ready" => 1
        room.append_player! player2
        room.amend_player! player2, "ready" => 1
        room.append_player! player3
        room.amend_player! player3, "ready" => 1
        room.append_player! player4
        room.amend_player! player4, "ready" => 1
      }
      it "locks the room" do
        expect(room.state).to eq Room::STATE_LOCKED
      end
      it "saves the rules correctly" do
        expect(room.srules["players"].count).to eq 4
      end
    end
    it "doesn't lock when someone isn't ready" do
      room.append_player! player1
      room.amend_player! player1, "ready" => 1
      room.append_player! player2
      room.amend_player! player2, "ready" => 1
      room.append_player! player3
      room.append_player! player4
      room.amend_player! player4, "ready" => 1
      expect(room.state).to eq Room::STATE_PUBLIC
    end
  end
  
  describe "#amend_player!" do
    include_context "when players have money"
    it "edits the player" do
      room.append_player! player1
      room.amend_player! player1, "wager" => 45
      expect(room.srules["players"][0]["wager"]).to eq 45
    end
    it "doesn't allow an incorrect wager" do
      room.append_player! player1
      room.amend_player! player1, "wager" => 10000
      expect(room.srules["players"][0]["wager"]).not_to eq 10000
    end
  end
end
