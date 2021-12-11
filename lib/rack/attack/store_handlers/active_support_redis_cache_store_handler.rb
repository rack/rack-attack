# frozen_string_literal: true

module Rack
  class Attack
    module StoreHandlers
      module ActiveSupportRedisCacheStoreHandler
        extend StoreHandlers

        def self.handles?(store)
          store.class.name == "ActiveSupport::Cache::RedisCacheStore"
        end

        def self.extract_backend(store)
          store.redis
        end

        def self.adapter_class
          Adapters::RedisAdapter
        end
      end
    end
  end
end
