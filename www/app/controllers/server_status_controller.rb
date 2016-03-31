class ServerStatusController < ApplicationController
  def index
    status
    respond_to do |format|
      format.html { render action: 'index' }
      format.json { render action: 'index' }
    end
  end
  
  def status
    @database = self.status_database
    @redis    = self.status_redis
    @mqst     = self.status_mq
    @server_status = self.status_servers
  end
  
  def status_database
    lcheck = $redis.get("GAMERISTSERVERSTATUSPOSTGRESTIMER")
    return ["ONLINE", lcheck] if(lcheck and lcheck.to_i > (Time.now.to_i - 30))
    x = Room.last
    $redis.set("GAMERISTSERVERSTATUSPOSTGRESTIMER", Time.now.to_i.to_s)
    return ["ONLINE", lcheck]
  end
  
  def status_redis
    tim = Time.now.to_i.to_s
    $redis.set("GAMERISTSERVERSTATUSCONTROLLER", tim)
    timr = $redis.get("GAMERISTSERVERSTATUSCONTROLLER")
    return ["ONLINE", timr] if(tim == timr)
    return ["OFFLINE", timr]
  end
  
  def status_mq
    lcheck = $redis.get("sstatusMQtimer")
    if((not lcheck) or lcheck.to_i < (Time.now.to_i - 30))
      DispatchMQ.send_self_test
      $redis.set("sstatusMQtimer", Time.now.to_i.to_s)
    end
    return [($redis.get("sstatusMQlasttime") or "none"), lcheck]
  end
  
  def status_servers
    x = Array.new
    $gamerist_serverdata["servers"].each do |s|
      raw  = $redis.hget("GAMERIST [Reports]", s["name"])
      dat = JSON.parse(raw) if raw
      x.push(dat) if dat
    end
    return x
  end
end
