# frozen_string_literal: true

require 'rack/attack/adapters/base'

module Rack
  class Attack
    module Adapters
      class RedisAdapter < Base
        def initialize(_redis)
          if Gem::Version.new(::Redis::VERSION) < Gem::Version.new("3")
            warn 'RackAttack requires Redis gem >= 3.0.0.'
          end

          super

          # Distinguish Redis::Distributed backends
          @distributed = backend.respond_to?(:node_for)
        end

        def read(key)
          with { |redis| redis.get(key) }
        end

        def write(key, value, options = {})
          with do |redis|
            if (expires_in = options[:expires_in])
              redis.setex(key, expires_in, value)
            else
              redis.set(key, value)
            end
          end
        end

        def increment(key, amount, options = {})
          with do |client|
            redis = @distributed ? client.node_for(key) : client

            redis.synchronize do
              redis.incrby(key, amount).tap do |count|
                redis.expire(key, options[:expires_in]) if count == amount && options[:expires_in]
              end
            end
          end
        end

        def delete(key)
          with { |redis| redis.del(key) }
        end

        def delete_matched(matcher)
          with do |redis|
            cursor = "0"

            nodes = @distributed ? redis.nodes : [redis]

            nodes.each do |node|
              # Fetch keys in batches using SCAN to avoid blocking the Redis server.
              loop do
                cursor, keys = node.scan(cursor, match: matcher, count: 1000)
                node.del(*keys) unless keys.empty?
                break if cursor == "0"
              end
            end
          end
        end

        private

        def rescue_from_error
          ::Redis::BaseConnectionError
        end
      end
    end
  end
end
