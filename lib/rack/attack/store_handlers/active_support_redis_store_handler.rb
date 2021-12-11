# frozen_string_literal: true

module Rack
  class Attack
    module StoreHandlers
      module ActiveSupportRedisStoreHandler
        extend StoreHandlers

        def self.handles?(store)
          store.class.name == "ActiveSupport::Cache::RedisStore"
        end

        def self.extract_backend(store)
          store.data
        end

        def self.adapter_class
          Adapters::RedisStoreAdapter
        end
      end
    end
  end
end
