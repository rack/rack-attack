module Rack
  class Attack
    module StoreProxy
      PROXIES = [DalliProxy, MemCacheProxy, RedisStoreProxy]

      def self.build(store)
        # RedisStore#increment needs different behavior, so detect that
        # (method has an arity of 2; must call #expire separately
        if (defined?(::ActiveSupport::Cache::RedisStore) && store.is_a?(::ActiveSupport::Cache::RedisStore)) ||
          (defined?(::ActiveSupport::Cache::MemCacheStore) && store.is_a?(::ActiveSupport::Cache::MemCacheStore))

          # ActiveSupport::Cache::RedisStore doesn't expose any way to set an expiry,
          # so use the raw Redis::Store instead.
          # We also want to use the underlying Dalli client instead of ::ActiveSupport::Cache::MemCacheStore,
          # and the MemCache client if using Rails 3.x
          client = store.instance_variable_get(:@data)
          if (defined?(::Redis::Store) && client.is_a?(Redis::Store)) ||
            (defined?(Dalli::Client) && client.is_a?(Dalli::Client)) || (defined?(MemCache) && client.is_a?(MemCache))
            store = store.instance_variable_get(:@data)
          end
        end
        klass = PROXIES.find { |proxy| proxy.handle?(store) }
        klass ? klass.new(store) : store
      end

    end
  end
end
