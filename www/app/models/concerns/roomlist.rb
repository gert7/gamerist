class RoomList
  # Add a Room to the potential roomlist Set in Redis
  def self.roomlist_add(room)
    $redis.sadd "gamerist_roomlist_potential", room.id
  end
  
  def self.roomlist_add_to_current(roomid, room)
    res = {id: roomid, rules: room.srules}
    $redis.rpush("gamerist_roomlist", JSON.generate(res))
    $redis.sadd("gamerist_roomlist_continents", room.srules["server_region"])
    $redis.rpush("gamerist_roomlist_continent_" + room.srules["server_region"], JSON.generate(res))
  end
  
  # Remove a specific Room from the potential list
  # @param [Integer] id ID of the Room model
  def self.remove_from_potential(id)
    $redis.srem("gamerist_roomlist_potential", id)
  end
  
  def self.roomlist_clear
    $redis.del("gamerist_roomlist")
    $redis.smembers("gamerist_roomlist_continents").each do |continent|
      $redis.del("gamerist_roomlist_continent_" + continent)
    end
    $redis.del("gamerist_roomlist_continents")
  end
  
  def self.roomlist_try_potential(roomid)
    room = Room.new(id: roomid.to_i)
    unless (room.is_alive? and (room.rstate == Room::STATE_PUBLIC))
      RoomList.remove_from_potential(roomid)
      return
    end
    # puts JSON.generate({id: v, rules: r.srules})
    RoomList.roomlist_add_to_current(roomid, room)
  end
  
  def self.roomlist_potens
    return $redis.smembers("gamerist_roomlist_potential")
  end
  
  # Produce the roomlist if the roomlist is over time limit
  def self.roomlist_produce()
    timeout = $redis.get("gamerist_roomlist_timeout")
    if Rails.env.test? or (not timeout or (timeout and timeout.to_i < Time.now.to_i))
      RoomList.roomlist_clear
      potens = RoomList.roomlist_potens
      potens.each do |v|
        RoomList.roomlist_try_potential(v)
      end
      $redis.set("gamerist_roomlist_timeout", Time.now.to_i + Room::TIMEOUT_ROOMLIST)
    end
  end
  
  # Retrieve the general roomlist's length
  def self.roomlist_length
    roomlist_produce
    $redis.llen "gamerist_roomlist"
  end
  
  # Retrieve a specific range of rooms from the general roomlist
  def self.roomlist_range(lrange, rrange)
    roomlist_produce
    $redis.lrange("gamerist_roomlist", lrange, rrange)
  end
  
  # Retrieve an entire roomlist of a specific continent
  def self.get_roomlist_by_continent(continent)
    roomlist_produce
    $redis.lrange(("gamerist_roomlist_continent_" + continent), 0, -1)
  end
end

