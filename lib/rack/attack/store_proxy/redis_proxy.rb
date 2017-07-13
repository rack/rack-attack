require 'delegate'

module Rack
  class Attack
    module StoreProxy
      class RedisProxy < RedisStoreProxy
        def self.handle?(store)
          defined?(::Redis) && store.is_a?(::Redis)
        end

        def initialize(store)
          super(store)
        end

        def get(key, _options = {})
          super(key)
        end

        def setex(key, ttl, value, _options = {})
          super(key, ttl, value)
        end

        def setnx(key, value, _options = {})
          super(key, value)
        end
      end
    end
  end
end
