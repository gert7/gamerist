require 'redis-lock'
require Rails.root.join("config", "initializers", "apikeys_accessor")

class Redis
  def fetch(n, &b)
    a = self.get(n)
    if(a)
      a
    else
      r = b.call()
      self.set(n, r)
      r
    end
  end
  
  def hfetch(h, k, &b)
    a = self.hget(h, k)
    if(a)
      a
    else
      r = b.call()
      self.hset(h, k, r)
      r
    end
  end
  
  def lock2(obj1, obj2, time, &block)
    self.lock(obj1, life: time) do
      self.lock(obj2, life: time) do
        block.call
      end
    end
  end
end

unless Gamerist.rake?
  redisuri = (Rails.env.production? ? GameristApiKeys.get("redis_production") : GameristApiKeys.get("redis_development"))

  $redis = ConnectionPool::Wrapper.new(size: 5, timeout: 5) { Redis.new(:url => redisuri) }
end

