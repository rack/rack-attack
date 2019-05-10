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
          rescuing { get(key) }
        end

        def write(key, value, options = {})
          if (expires_in = options[:expires_in])
            rescuing { setex(key, expires_in, value) }
          else
            rescuing { set(key, value) }
          end
        end

        def increment(key, amount, options = {})
          count = nil

          rescuing do
            pipelined do
              count = incrby(key, amount)
              expire(key, options[:expires_in]) if options[:expires_in]
            end
          end

          count.value if count
        end

        def delete(key, _options = {})
          rescuing { del(key) }
        end

        private

        def rescuing
          yield
        rescue Redis::BaseError
          nil
        end
      end
    end
  end
end
