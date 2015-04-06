require 'spec_helper'

describe Room do
  before(:each) do
  end

  describe "#make_room" do
    it "successfully creates a new room" do
      r = Room.create_room("team fortress 2", "ctf_2fort", 16, 5)
      expect(r.new_record?).to eq false
    end
    
    it "fails because the parameters are wrong" do
      r1 = Room.create_room("team fooftress 2", "ctf_2fort", 8, 5)
      expect(r1.new_record?).to eq true
      r2 = Room.create_room("team fortress 2", "cp_2fort", 8, 5)
      expect(r2.new_record?).to eq true
      r3 = Room.create_room("team fortress 2", "ctf_2fort", 9, 5)
      expect(r3.new_record?).to eq true
      r4 = Room.create_room("team fortress 2", "ctf_2fort", 8, -2)
      expect(r4.new_record?).to eq true
    end
  end
end

