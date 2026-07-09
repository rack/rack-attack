# frozen_string_literal: true

require 'rack/attack/store_proxy/redis_proxy'

module Rack
  class Attack
    module StoreProxy
      class RedisStoreProxy < RedisProxy
        def self.handle?(store)
          defined?(::Redis::Store) && store.is_a?(::Redis::Store)
        end

        def read(key)
          handle_store_error { get(key, raw: true) }
        end

        def write(key, value, options = {})
          if (expires_in = options[:expires_in])
            handle_store_error { setex(key, expires_in, value, raw: true) }
          else
            handle_store_error { set(key, value, raw: true) }
          end
        end
      end
    end
  end
end
