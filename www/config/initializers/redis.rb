require 'redis-lock'
require 'config/initializers/apikeys_accessor'

class Redis
  def fetch n, &b
    a = self.get(n)
    if(a)
      a
    else
      r = b.call()
      self.set(n, r)
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

if(Rails.env.production?)
  $redis = ConnectionPool::Wrapper.new(size: 5, timeout: 5) { Redis.new(:url => "redis://" + $GAMERIST_API_KEYS["redis_production"]) }
else
  $redis = ConnectionPool::Wrapper.new(size: 5, timeout: 5) { Redis.new(:url => "redis://" + $GAMERIST_API_KEYS["redis_development"]) }
end

