module Rack
  class Attack
    module StoreProxy
      PROXIES = [DalliProxy, RedisStoreProxy]

      def self.build(store)
        # RedisStore#increment needs different behavior, so detect that
        # (method has an arity of 2; must call #expire separately
        if defined?(::ActiveSupport::Cache::RedisStore) && store.is_a?(::ActiveSupport::Cache::RedisStore)
          # ActiveSupport::Cache::RedisStore doesn't expose any way to set an expiry,
          # so use the raw Redis::Store instead
          store = store.instance_variable_get(:@data)
        end

        klass = PROXIES.find { |proxy| proxy.handle?(store) }

        klass ? klass.new(store) : store
      end

    end
  end
end
