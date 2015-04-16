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
end

if(Rails.env.production?)
  $redis = ConnectionPool::Wrapper.new(size: 5, timeout: 5) { Redis.new(:url => "redis://" + $GAMERIST_API_KEYS["redis_production"]) }
else
  $redis = ConnectionPool::Wrapper.new(size: 5, timeout: 5) { Redis.new(:url => "redis://" + $GAMERIST_API_KEYS["redis_development"]) }
end

