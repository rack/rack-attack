# frozen_string_literal: true

require 'delegate'

module Rack
  class Attack
    module StoreProxy
      class RedisCacheStoreProxy < SimpleDelegator
        def self.handle?(store)
          store.class.name == "ActiveSupport::Cache::RedisCacheStore"
        end

        def increment(name, amount = 1, options = {})
          rescuing do
            redis.with do |conn|
              conn.multi do
                conn.incrby(name, amount)
                conn.expire(name, options[:expires_in]) if options[:expires_in]
              end.first
            end
          end
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
