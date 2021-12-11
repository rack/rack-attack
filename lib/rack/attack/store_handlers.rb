# frozen_string_literal: true

module Rack
  class Attack
    module StoreHandlers
      @handlers = []

      class << self
        def extended(handler)
          @handlers << handler
        end

        def adapter_for(store)
          lookup(store)&.build_adapter(store)
        end

        def lookup(store)
          @handlers.find { |handler| handler.handles?(store) }
        end
      end

      def build_adapter(store)
        adapter_class.new(extract_backend(store))
      end

      def extract_backend(store)
        store
      end

      def adapter_class
        raise NotImplementedError
      end

      def handles?(_store)
        raise NotImplementedError
      end

      private

      def instance_of_or_pooled?(store, klass)
        if defined?(::ConnectionPool) && store.is_a?(::ConnectionPool)
          store.with { |conn| conn.instance_of?(klass) }
        else
          store.instance_of?(klass)
        end
      end
    end
  end
end

require_relative 'store_handlers/active_support_redis_cache_store_handler'
require_relative 'store_handlers/active_support_mem_cache_store_handler'
require_relative 'store_handlers/active_support_memory_store_handler'
require_relative 'store_handlers/active_support_redis_store_handler'
require_relative 'store_handlers/dalli_client_handler'
require_relative 'store_handlers/redis_store_handler'
require_relative 'store_handlers/redis_handler'
