# frozen_string_literal: true

require 'rack/attack/base_proxy'

module Rack
  class Attack
    module StoreProxy
      class RedisProxy < BaseProxy
        def self.handle?(store)
          defined?(::Redis) && store.class == ::Redis
        end

        def initialize(_store)
          if Gem::Version.new(Redis::VERSION) < Gem::Version.new("3")
            warn 'RackAttack requires Redis gem >= 3.0.0.'
          end

          super
        end

        def read(key)
          rescuing_with { |c| c.get(key) }
        end

        def write(key, value, options = {})
          if (expires_in = options[:expires_in])
            rescuing_with { |c| c.setex(key, expires_in, value) }
          else
            rescuing_with { |c| c.set(key, value) }
          end
        end

        def increment(key, amount, options = {})
          rescuing_with do |c|
            c.synchronize do |client|
              client.call([:incrby, key, amount]).tap do |count|
                client.call([:expire, key, options[:expires_in]]) if count == amount && options[:expires_in]
              end
            end
          end
        end

        def delete(key, _options = {})
          rescuing_with { |c| c.del(key) }
        end

        def delete_matched(matcher, _options = nil)
          cursor = "0"

          rescuing_with do |c|
            # Fetch keys in batches using SCAN to avoid blocking the Redis server.
            loop do
              cursor, keys = c.scan(cursor, match: matcher, count: 1000)
              c.del(*keys) unless keys.empty?
              break if cursor == "0"
            end
          end
        end

        private

        def rescuing_with
          with { |c| yield c }
        rescue Redis::BaseConnectionError
          nil
        end
      end
    end
  end
end
