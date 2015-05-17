require 'redis'
require 'redis-lock'
require 'json'

module Agis
  @agis_methods = Hash.new

  def agis_mailbox
    "AGIS TERMINAL : " + self.class.to_s + " : " + self.id.to_s
  end
  
  def agis_defm0(name, &b)
    @agis_methods[name] = [0, Proc.new do |redis|
      redis.rpush self.agis_mailbox, name
    end]
  end
  
  def agis_defm1(name, &b)
    @agis_methods[name] = [1, Proc.new do |redis, arg1|
      redis.rpush self.agis_mailbox, name
      redis.rpush self.agis_mailbox, arg1.to_json
    end]
  end
  
  def agis_defm2(name, &b)
    @agis_methods[name] = [2, Proc.new do |redis, arg1, arg2|
      redis.rpush self.agis_mailbox, name
      redis.rpush self.agis_mailbox, arg1.to_json
      redis.rpush self.agis_mailbox, arg2.to_json
    end]
  end
  
  def agis_defm3(name, &b)
    @agis_methods[name] = [3, Proc.new do |redis, arg1, arg2, arg3|
      redis.rpush self.agis_mailbox, name
      redis.rpush self.agis_mailbox, arg1.to_json
      redis.rpush self.agis_mailbox, arg2.to_json
      redis.rpush self.agis_mailbox, arg3.to_json
    end]
  end
  
  def _agis_crunch(lock, redis)
    loop do
      if mn = redis.lpop(self.agis_mailbox)
        args = []
        mc = @agis_methods[mn][0]
        met = @agis_methods[mn][1]
        mc.times do
          args.push JSON.parse(redis.lpop(self.agis_mailbox), symbolize_names: true)
        end
        case mc
        when 0
          @last = met.call()
        when 1
          @last = met.call(args[0])
        when 2
          @last = met.call(args[0], args[1])
        when 3
          @last = met.call(args[0], args[1], args[2])
        end
        lock.extend_life 4
      else
        return @last or nil
      end
    end
  end
  
  # Crunch if the lock is available, returns when box is empty, lock timeout 1 second
  def agis_ncrunch(redis)
    redis.lock(agis_mailbox + ".LOCK", life: 4, acquire: 1) do |lock|
      _agis_crunch(lock, redis)
    end
  end
  
  # Wait until the lock is available, returns when box is empty, lock timeout 60 seconds
  def agis_bcrunch(redis)
    redis.lock(agis_mailbox + ".LOCK", life: 4, acquire: 60) do |lock|
      _agis_crunch(lock, redis)
    end
  end
  
  # Wait until the lock is available, crunch forever
  def agis_lcrunch(redis)
    redis.lock(agis_mailbox + ".LOCK", life: 1200, acquire: 1200) do |lock|
      loop do
        _agis_crunch(lock, redis)
        lock.extend_life(60)
      end
    end
  end
end

