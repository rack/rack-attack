# frozen_string_literal: true

require 'delegate'

module Rack
  class Attack
    module StoreProxy
      class RedisStoreProxy < RedisProxy
        def self.handle?(store)
          defined?(::Redis::Store) && store.is_a?(::Redis::Store)
        end

        def read(key)
          get(key, raw: true)
        rescue Redis::BaseError
          nil
        end

        def write(key, value, options = {})
          if (expires_in = options[:expires_in])
            setex(key, expires_in, value, raw: true)
          else
            set(key, value, raw: true)
          end
        rescue Redis::BaseError
          nil
        end
      end
    end
  end
end
