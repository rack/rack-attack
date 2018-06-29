# frozen_string_literal: true

require 'delegate'

module Rack
  class Attack
    module StoreProxy
      class RedisProxy < SimpleDelegator
        def self.handle?(store)
          defined?(::Redis) && store.is_a?(::Redis)
        end

        def initialize(store)
          super(store)
        end

        def read(key)
          get(key)
        end

        def write(key, value, options = {})
          if (expires_in = options[:expires_in])
            setex(key, expires_in, value)
          else
            set(key, value)
          end
        end

        def increment(key, amount, options = {})
          count = nil

          pipelined do
            count = incrby(key, amount)
            expire(key, options[:expires_in]) if options[:expires_in]
          end

          count.value if count
        end

        def delete(key, _options = {})
          del(key)
        end
      end
    end
  end
end
