# frozen_string_literal: true

require 'rack/attack/base_proxy'

module Rack
  class Attack
    module StoreProxy
      class RedisProxy < BaseProxy
        def initialize(store, **options)
          if Gem::Version.new(Redis::VERSION) < Gem::Version.new("3")
            warn 'RackAttack requires Redis gem >= 3.0.0.'
          end

          super(store, **options)
        end

        def self.handle?(store)
          defined?(::Redis) && store.class == ::Redis
        end

        def read(key)
          handle_store_error { get(key) }
        end

        def write(key, value, options = {})
          if (expires_in = options[:expires_in])
            handle_store_error { setex(key, expires_in, value) }
          else
            handle_store_error { set(key, value) }
          end
        end

        def increment(key, amount, options = {})
          handle_store_error do
            pipelined do |redis|
              redis.incrby(key, amount)
              redis.expire(key, options[:expires_in]) if options[:expires_in]
            end.first
          end
        end

        def delete(key, _options = {})
          handle_store_error { del(key) }
        end

        def delete_matched(matcher, _options = nil)
          cursor = "0"
          source = matcher.source

          handle_store_error do
            # Fetch keys in batches using SCAN to avoid blocking the Redis server.
            loop do
              cursor, keys = scan(cursor, match: source, count: 1000)
              del(*keys) unless keys.empty?
              break if cursor == "0"
            end
          end
        end

        private

        def should_bypass_error?(error)
          # Redis-specific default behavior: bypass Redis connection errors
          return true if error.is_a?(Redis::BaseConnectionError)
          super
        end
      end
    end
  end
end
