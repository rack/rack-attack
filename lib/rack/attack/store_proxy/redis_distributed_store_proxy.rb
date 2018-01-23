require 'delegate'
require 'rack/attack/store_proxy/redis_store_proxy'

module Rack
  class Attack
    module StoreProxy
      class RedisDistributedStoreProxy < RedisStoreProxy
        def self.handle?(store)
          defined?(::Redis::DistributedStore) && store.is_a?(::Redis::DistributedStore)
        end

        # overrride #increment to use a Lua script as Redis::Distributed
        # does not support pipelining (even when all keys got to the same node)
        def increment(key, amount, options={})
          evalsha(script_sha, keys: [key], argv:[amount, options[:expires_in]])
        rescue Redis::BaseError
        end

        private

        def script_sha
          @script_sha ||= begin
            shas = script 'load', %{
              -- KEYS[1]: key to increment
              -- ARGV[1]: amount to increment by
              -- ARGV[2]: updated TTL if any
              local value = redis.call('INCRBY', KEYS[1], tonumber(ARGV[1]))
              local ttl = tonumber(ARGV[2])
              if ttl then
                redis.call('EXPIRE', KEYS[1], ttl)
              end
              return value
            }
            shas.kind_of?(Array) ? shas.first : shas
          end
        end
      end
    end
  end
end
