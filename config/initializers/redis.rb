require 'redis-lock'

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

$redis = ConnectionPool::Wrapper.new(size: 5, timeout: 5) { Redis.new }

