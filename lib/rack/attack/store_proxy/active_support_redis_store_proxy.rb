# frozen_string_literal: true

require 'rack/attack/base_proxy'

module Rack
  class Attack
    module StoreProxy
      class ActiveSupportRedisStoreProxy < BaseProxy
        def self.handle?(store)
          defined?(::Redis) &&
            defined?(::ActiveSupport::Cache::RedisStore) &&
            store.is_a?(::ActiveSupport::Cache::RedisStore)
        end

        def self.build(store)
          RedisStoreProxy.build(store.data)
        end
      end
    end
  end
end
