def cache_fetch_else(k, &proc)
  if (a = Rails.cache.fetch k)
    return a
  else
    Rails.cache.write k, proc.call
    Rails.cache.fetch k
  end
end

module ActiveRecord
  class Base
    def cache_symbol(k)
      self.class.name + "-#{self.id}[#{k}]"
    end
    
    def cache_fetch_symbol_else(k, &proc)
      cache_fetch_else(cache_symbol(k), &proc)
    end
  end
end

$redis = ConnectionPool.new(size: 5, timeout: 5) { Redis.new }

