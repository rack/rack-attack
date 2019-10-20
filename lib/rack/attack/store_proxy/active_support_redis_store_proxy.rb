# frozen_string_literal: true

require 'delegate'

module Rack
  class Attack
    module StoreProxy
      class ActiveSupportRedisStoreProxy < SimpleDelegator
        def self.handle?(store)
          defined?(::Redis) &&
            defined?(::ActiveSupport::Cache::RedisStore) &&
            store.is_a?(::ActiveSupport::Cache::RedisStore)
        end

        def increment(name, amount = 1, options = {})
          rescuing do
            with do |conn|
              conn.multi do
                conn.incrby(name, amount)
                conn.expire(name, options[:expires_in]) if options[:expires_in]
              end.first
            end
          end
        end

        def read(name, options = {})
          super(name, options.merge!(raw: true))
        end

        def write(name, value, options = {})
          super(name, value, options.merge!(raw: true))
        end

        private

        def rescuing
          yield
        rescue Redis::BaseConnectionError
          nil
        end
      end
    end
  end
end
