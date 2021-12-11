# frozen_string_literal: true

require 'rack/attack/base_proxy'

module Rack
  class Attack
    module StoreProxy
      class MemCacheStoreProxy < BaseProxy
        def self.handle?(store)
          defined?(::Dalli) &&
            defined?(::ActiveSupport::Cache::MemCacheStore) &&
            store.is_a?(::ActiveSupport::Cache::MemCacheStore)
        end

        def self.build(store)
          DalliProxy.build(store.instance_variable_get(:@data))
        end
      end
    end
  end
end
