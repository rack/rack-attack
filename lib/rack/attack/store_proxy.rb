module Rack
  class Attack
    module StoreProxy
      PROXIES = [DalliProxy, MemCacheStoreProxy, MemCacheProxy, RedisStoreProxy, RedisProxy, RedisCacheStoreProxy].freeze

      def self.build(store)
        client = unwrap_active_support_stores(store)
        klass = PROXIES.find { |proxy| proxy.handle?(client) }
        klass ? klass.new(client) : client
      end

      def self.unwrap_active_support_stores(store)
        # ActiveSupport::Cache::RedisStore doesn't expose any way to set an expiry,
        # so use the raw Redis::Store instead.
        if store.class.name == 'ActiveSupport::Cache::RedisStore'
          store.instance_variable_get(:@data)
        else
          store
        end
      end
    end
  end
end
