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

        def read(name, options = {})
          handle_store_error { super(name, options.merge!(raw: true)) }
        end

        def write(name, value, options = {})
          handle_store_error { super(name, value, options.merge!(raw: true)) }
        end
      end
    end
  end
end
