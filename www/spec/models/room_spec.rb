# == Schema Information
#
# Table name: rooms
#
#  id         :integer          not null, primary key
#  state      :integer
#  created_at :datetime
#  updated_at :datetime
#  rules      :text
#

###################
#    IMPORTANT    #
###################

# pay attention to included contexts:
# 'when players have money'

require 'spec_helper'

describe Room do
  let(:room) { FactoryGirl.create :room }
  let(:player1) { FactoryGirl.create(:player1) }
  let(:player2) { FactoryGirl.create(:player2) }
  let(:player3) { FactoryGirl.create(:player3) }
  let(:player4) { FactoryGirl.create(:player4) }
  let(:player5) { FactoryGirl.create(:player5) }
  let(:room2) { FactoryGirl.create :room2 }

  shared_context("when players have money") do
    before {
      room.save
      Transaction.make_transaction(user_id: player1.id, amount: 25, state: Transaction::STATE_FINAL, kind: Transaction::KIND_PAYPAL, detail: 1)
      Transaction.make_transaction(user_id: player2.id, amount: 25, state: Transaction::STATE_FINAL, kind: Transaction::KIND_PAYPAL, detail: 2)
      Transaction.make_transaction(user_id: player3.id, amount: 25, state: Transaction::STATE_FINAL, kind: Transaction::KIND_PAYPAL, detail: 3)
      Transaction.make_transaction(user_id: player4.id, amount: 25, state: Transaction::STATE_FINAL, kind: Transaction::KIND_PAYPAL, detail: 4)
      Transaction.make_transaction(user_id: player5.id, amount: 25, state: Transaction::STATE_FINAL, kind: Transaction::KIND_PAYPAL, detail: 5)
      #User.any_instance.stubs(:total_balance).returns 25
    }
  end
  
  shared_context("when players have no money") do
    before {
      User.any_instance.stubs(:total_balance).returns 0
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
      r5 = Room.create(game: "team fortress 2", map: "ctf_2fort", playercount: 24, wager: 10)
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
      include_context "when players have money"
      it "adds the player successfully" do
        room.append_player! player1
        room.update_xhr(player1, {"team" => 2})
        expect(player1.is_reserved?).to eq true
        expect(room.srules["players"].count).to eq 1
        expect(room.srules["players"][0]["id"]).to eq player1.id
      end
      it "doesn't allow joining several rooms" do
        room.append_player! player1
        room.update_xhr(player1, {"team" => 2})
        room2.append_player! player1
        room2.update_xhr(player1, {"team" => 2})
        expect(room2.total_players(room2.srules)).to eq 0
      end
      it "reserves the player" do
        room.append_player! player1
        room.update_xhr(player1, {"team" => 2})
        expect(player1.is_reserved?).to eq true
      end
      it "adds multiple players" do
        room.append_player! player1
        room.update_xhr(player1, {"team" => 2})
        room.append_player! player2
        room.update_xhr(player2, {"team" => 2})
        room.append_player! player3
        room.update_xhr(player3, {"team" => 3})
        expect(room.srules["players"].count).to eq 3
      end
    end
    context "when players don't have money" do
      include_context "when players have no money"
      it "will not add the player" do
        room.append_player! player1
        room.update_xhr(player1, {"team" => 2})
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
        r1.update_xhr(player1, {"team" => 2})
        r2.append_player! player1
        r2.update_xhr(player1, {"team" => 2})
        expect(r1.srules["players"].count).to eq 1
      end
      it "will affect the other instance" do
        r1 = Room.find(room.id)
        r2 = Room.find(room.id)
        r1.append_player! player1
        r1.update_xhr(player1, {"team" => 2})
        expect(r2.srules["players"].count).to eq 1
      end
    end
    context "when server region is Europe" do
      include_context "when players have money"
      it "will not add the player from America" do
        room.update_xhr(player1, {"team" => 2}, "North America")
        expect(room.srules["players"].count).to eq 0
      end
      it "will add the player from Europe" do
        room.update_xhr(player1, {"team" => 2}, "Europe")
        expect(room.srules["players"].count).to eq 1
      end
    end
  end
  
  describe "#remove_player!" do
    include_context "when players have money"
    it "removes the player from the room" do
      room.amend_player! player1, "team" => 2
      expect(room.srules["players"].count).to eq 1
      room.remove_player! player1
      expect(room.srules["players"].count).to eq 0
    end
    it "unreserves the player" do
      room.append_player! player1
      room.update_xhr(player1, {"team" => 2})
      room.remove_player! player1
      expect(player1.is_reserved?).to eq false
    end
    it "removes the player from between" do
      room.amend_player! player1, "team" => 2
      room.amend_player! player2, "team" => 2
      room.amend_player! player3, "team" => 3
      room.remove_player! player2
      expect(room.srules["players"].count).to eq 2
      expect(room.srules["players"][1]["id"]).to eq player3.id
    end
  end
  
  describe "#check_wager" do
    include_context "when players have money"
    before {
      room.append_player! player1
      room.update_xhr(player1, {"team" => 2})
      room.append_player! player2
      room.update_xhr(player2, {"team" => 2})
      room.amend_player! player1, "wager" => 10
      room.amend_player! player2, "wager" => 8
    }
    it "increases wager to lowest common PW" do
      expect(room.srules["wager"]).to eq 8
    end
    it "decreases wager to highest common PW" do
      room.amend_player! player1, "wager" => 7
      room.amend_player! player2, "wager" => 5
      expect(room.srules["wager"]).to eq 7
    end
    it "increases wager on player leave" do
      room.remove_player! player2
      room.amend_player! player1, {}
      expect(room.srules["wager"]).to eq 10
    end
    it "doesn't allow backsies" do
      room.amend_player! player2, "wager" => 10
      room.amend_player! player2, "wager" => 8
      expect(room.srules["wager"]).to eq 10
    end
    it "reduces wager on player leave" do
      room.remove_player! player1
      room.amend_player! player2, {}
      expect(room.srules["wager"]).to eq 8
    end
  end
  
  describe "#check_ready" do
    include_context "when players have money"
    context "when everyone is ready" do
      before {
        room.amend_player! player1, "team" => 2, "ready" => 1
        room.amend_player! player2, "team" => 2, "ready" => 1
        room.amend_player! player3, "team" => 3, "ready" => 1
        room.amend_player! player4, "team" => 3, "ready" => 1
      }
      it "locks the room" do
        expect(room.rstate).to eq Room::STATE_LOCKED
      end
      it "saves the rules correctly" do
        expect(room.srules["players"].count).to eq 4
      end
    end
    it "doesn't lock when someone isn't ready" do
      room.amend_player! player1, "ready" => 1
      room.amend_player! player2, "ready" => 1
      room.amend_player! player3, {}
      room.amend_player! player4, "ready" => 1
      expect(room.rstate).to eq Room::STATE_PUBLIC
    end
  end
  
  describe "#remove_exo_players" do
    include_context "when players have money"
    it "removes all non-teamed players" do
      room.amend_player! player1, "team" => 2, "ready" => 1
      room.amend_player! player2, "team" => 2, "ready" => 1
      room.amend_player! player3, "team" => 3, "ready" => 1
      room.amend_player! player4, {}
      expect(room.rstate).to eq Room::STATE_PUBLIC
      room.amend_player! player5, "team" => 3, "ready" => 1
      expect(room.rstate).to eq Room::STATE_LOCKED
      expect(room.total_players(room.srules)).to eq 4
      expect(room.srules["players"].count).to eq 4
    end
  end
  
  describe "#amend_player!" do
    include_context "when players have money"
    it "edits the player" do
      room.amend_player! player1, "team" => 2
      expect(room.srules["players"][0]["wager"]).to eq 5
      room.amend_player! player1, "wager" => 15
      expect(room.srules["players"][0]["wager"]).to eq 15
    end
    it "doesn't allow an incorrect wager" do
      room.append_player! player1
      room.amend_player! player1, "wager" => 10000, "team" => 2
      expect(room.srules["players"][0]["wager"]).not_to eq 10000
    end
    it "adds the player if they're not already in" do
      expect(room.srules["players"].count).to eq 0
      room.amend_player! player1, {"wager" => 10, "team" => 2}
      expect(room.srules["players"][0]["wager"]).to eq 10
    end
    it "doesn't allow a wager greater than funds" do
      room.append_player! player1 # only has 25
      room.amend_player! player1, {"wager" => 45, "team" => 2}
      expect(room.srules["players"][0]["wager"]).not_to eq 45
    end
    it "removes the player if they lose the reservation" do
      room.append_player! player1
      player1.unreserve_from_room(room.id)
      room2.append_player! player1 # make another reservation
      room.amend_player! player1, "wager" => 8
      expect(room.total_players(room.srules)).to eq 0
    end
  end
  
  describe "#update_xhr" do
    include_context "when players have money"
    it "modifies the player" do
      room.amend_player! player1, "team" => 2
      room.update_xhr(player1, {"wager" => 10, "ready" => 1})
      expect(room.srules["players"][0]["wager"]).to eq 10
      expect(room.srules["players"][0]["ready"]).to eq "1"
    end
    it "removes the player if wager is zero" do
      room.append_player! player1
      room.update_xhr(player1, {"wager" => 0, "ready" => 0})
      expect(room.srules["players"].count).to eq 0
    end
  end
  
  describe "#dump_timeout_players" do
    include_context "when players have money"
    it "throws out timed out players" do
      room.append_player! player1
      room.update_xhr(player1, {"team" => 2})
      room.append_player! player2
      room.update_xhr(player2, {"team" => 2})
      expect(room.srules["players"].count).to eq 2
      
      mrules = room.srules
      mrules["players"][0]["timeout"] = Time.now.to_i - 40
      room.srules = mrules
      
      room.update_xhr(player2, {"wager" => 10, "ready" => 1})
      expect(room.srules["players"].count).to eq 1
    end
  end
  
  describe "#assign_to_team" do
    include_context "when players have money"
    it "assigns the selected team" do
      room.append_player! player1
      room.update_xhr(player1, {"team" => 2})
      room.append_player! player2
      room.update_xhr(player2, {"team" => 2})
      room.append_player! player3
      room.update_xhr(player3, {"team" => 2})
      room.append_player! player4
      room.update_xhr(player4, {"team" => 2})
      expect(room.srules["players"][0]["team"]).to eq 2
      expect(room.srules["players"][1]["team"]).to eq 2
      expect(room.srules["players"][2]["team"]).to eq 0
      expect(room.srules["players"][3]["team"]).to eq 0
    end
  end
  
  describe "#declare_winning_team" do
    include_context "when players have money"
    before do
      room.amend_player! player1, "team" => 2
      room.amend_player! player2, "team" => 2
      room.amend_player! player3, "team" => 3
      room.amend_player! player4, "team" => 3
      room.rstate = Room::STATE_ACTIVE
    end
    
    it "distributes winnings" do
      room.declare_winning_team(2)
      expect(player1.total_balance).to eq 30
    end
    
    it "allows srules and rstate to be accessed" do
      room.declare_winning_team(2)
      expect(room.srules.class).to eq Hash
      expect(room.rstate.class).to eq Fixnum
    end
  end
  
  describe "#declare_team_scores" do
    include_context "when players have money"
    it "specifies scores" do
      room.amend_player! player1, "team" => 2
      room.amend_player! player2, "team" => 2
      room.amend_player! player3, "team" => 3
      room.amend_player! player4, "team" => 3
      room.declare_team_scores([{"steamid": player1.steamid.steamid2, "score": 81}])
      expect(room.srules["players"][0]["score"]).to eq 81
    end
  end
  
  describe "#update_relevant_users" do
    include_context "when players have money"
    it "updates relevant users" do
      room.amend_player! player1, "team" => 2
      room.amend_player! player2, "team" => 2
      room.amend_player! player3, "team" => 3
      room.amend_player! player4, "team" => 3
      room.update_relevant_users(room.srules)
      player1.reload
      expect(player1.relevantgames).to eq (room.id.to_s + ";")
    end
  end
  
  describe "#roomlist_produce" do
    include_context "when players have money"
    it "adds the room to the list" do
      expect(RoomList.roomlist_length).to eq 1
    end
    
    it "removes the room from the list" do
      room.amend_player! player1, "team" => 2
      room.amend_player! player2, "team" => 2
      room.amend_player! player3, "team" => 3
      room.amend_player! player4, "team" => 3
      room.rstate = Room::STATE_ACTIVE
      room.declare_winning_team(2)
      expect(RoomList.roomlist_length).to eq 0
    end
    
    it "puts the room on the continental list" do
      expect(RoomList.get_roomlist_by_continent("Europe").length).to eq 1
      expect(RoomList.get_roomlist_by_continent("North America").length).to eq 0
    end
    
    it "removes the room from the continental list" do
      room.amend_player! player1, "team" => 2
      room.amend_player! player2, "team" => 2
      room.amend_player! player3, "team" => 3
      room.amend_player! player4, "team" => 3
      room.rstate = Room::STATE_ACTIVE
      room.declare_winning_team(2)
      expect(RoomList.get_roomlist_by_continent("Europe").length).to eq 0
    end
  end
  
  describe "expire_room!" do
    it "expires the room and allows srules and rstate to be read" do
      room.expire_room!
      expect(room.srules.class).to eq Hash
      expect(room.rstate.class).to eq Fixnum
    end
  end
end

