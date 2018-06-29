require 'delegate'

module Rack
  class Attack
    module StoreProxy
      class RedisStoreProxy < SimpleDelegator
        def initialize(*args)
          if Gem::Version.new(Redis::VERSION) < Gem::Version.new("3")
            warn 'RackAttack requires Redis gem >= 3.0.0.'
          end

          super(*args)
        end

        def self.handle?(store)
          defined?(::Redis::Store) && store.is_a?(::Redis::Store)
        end

        def read(key)
          get(key, raw: true)
        rescue Redis::BaseError
        end

        def write(key, value, options = {})
          if (expires_in = options[:expires_in])
            setex(key, expires_in, value, raw: true)
          else
            set(key, value, raw: true)
          end
        rescue Redis::BaseError
        end

        def increment(key, amount, options = {})
          count = nil

          pipelined do
            count = incrby(key, amount)
            expire(key, options[:expires_in]) if options[:expires_in]
          end

          count.value if count
        rescue Redis::BaseError
        end

        def delete(key, _options = {})
          del(key)
        rescue Redis::BaseError
        end
      end
    end
  end
end
