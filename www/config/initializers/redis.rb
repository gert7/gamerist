$redis = ConnectionPool::Wrapper.new(size: 5, timeout: 5) { Redis.new }

