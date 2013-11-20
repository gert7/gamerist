module ActiveRecord
  class Base
    def cache_key(k)
      self.class.name + "-#{self.id}[#{k}]"
    end
    
    def cache_fetch_else(k, &proc)
      if (a = Rails.cache.fetch k)
        return a
      else
        proc.call
        Rails.cache.fetch k
      end
    end
    
    def cache_fetch_key_else(k, &proc)
      cache_fetch_else(cache_key(k), &proc)
    end
  end
end
