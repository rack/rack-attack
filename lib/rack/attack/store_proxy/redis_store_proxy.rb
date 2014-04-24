require 'delegate'

module Rack
  class Attack
    module StoreProxy
      class RedisStoreProxy < SimpleDelegator
        def self.handle?(store)
          defined?(::Redis::Store) && store.is_a?(::Redis::Store)
        end

        def initialize(store)
          super(store)
        end

        def read(key)
          self.get(key)
        rescue Redis::BaseError
        end

        def write(key, value, options={})
          if (expires_in = options[:expires_in])
            self.setex(key, expires_in, value)
          else
            self.set(key, value)
          end
        rescue Redis::BaseError
        end

        def increment(key, amount, options={})
          count = nil
          self.pipelined do
            count = self.incrby(key, amount)
            self.expire(key, options[:expires_in]) if options[:expires_in]
          end
          count.value if count
        rescue Redis::BaseError
        end

      end
    end
  end
end
