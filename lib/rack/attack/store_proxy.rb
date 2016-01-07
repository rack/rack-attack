module Rack
  class Attack
    module StoreProxy
      PROXIES = [DalliProxy, MemCacheProxy, RedisStoreProxy]
      USE_BASE_CLIENT = ['Redis::Store', 'Dalli::Client', 'MemCache']

      def self.build(store)
        # RedisStore#increment needs different behavior, so detect that
        # (method has an arity of 2; must call #expire separately
        client = fetch_client(store)
        klass = PROXIES.find { |proxy| proxy.handle?(client) }
        klass ? klass.new(client) : client
      end

      def self.fetch_client(store)
        client = store.instance_variable_get(:@data)
        # RedisStore#increment needs different behavior, so detect that
        # (method has an arity of 2; must call #expire separately
        #
        # ActiveSupport::Cache::RedisStore doesn't expose any way to set an expiry,
        # so use the raw Redis::Store instead.
        #
        # We also want to use the underlying Dalli client instead of ::ActiveSupport::Cache::MemCacheStore,
        # and the MemCache client if using Rails 3.x
        USE_BASE_CLIENT.each do |klass|
          return client if !client.nil? && Object.const_defined?(klass) && client.is_a?(Object.const_get(klass))
        end
        return store
      end

    end
  end
end
