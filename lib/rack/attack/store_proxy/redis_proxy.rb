# frozen_string_literal: true

require 'delegate'

module Rack
  class Attack
    module StoreProxy
      class RedisProxy < SimpleDelegator
        def initialize(*args)
          if Gem::Version.new(Redis::VERSION) < Gem::Version.new("3")
            warn 'RackAttack requires Redis gem >= 3.0.0.'
          end

          super(*args)
        end

        def self.handle?(store)
          defined?(::Redis) && store.is_a?(::Redis)
        end

        def read(key)
          get(key)
        rescue Redis::BaseError
          nil
        end

        def write(key, value, options = {})
          if (expires_in = options[:expires_in])
            setex(key, expires_in, value)
          else
            set(key, value)
          end
        rescue Redis::BaseError
          nil
        end

        def increment(key, amount, options = {})
          count = nil

          pipelined do
            count = incrby(key, amount)
            expire(key, options[:expires_in]) if options[:expires_in]
          end

          count.value if count
        rescue Redis::BaseError
          nil
        end

        def delete(key, _options = {})
          del(key)
        rescue Redis::BaseError
          nil
        end
      end
    end
  end
end
