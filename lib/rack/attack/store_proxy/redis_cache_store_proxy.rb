# frozen_string_literal: true

require 'rack/attack/base_proxy'

module Rack
  class Attack
    module StoreProxy
      class RedisCacheStoreProxy < BaseProxy
        def self.handle?(store)
          store.class.name == "ActiveSupport::Cache::RedisCacheStore"
          # defined?(store.redis) && store.redis.is_a?(::Redis)
        end

        def self.build(store)
          RedisProxy.build(store.redis)
        end
      end
    end
  end
end
