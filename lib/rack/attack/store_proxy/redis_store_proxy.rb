# frozen_string_literal: true

require 'rack/attack/store_proxy/redis_proxy'

module Rack
  class Attack
    module StoreProxy
      class RedisStoreProxy < RedisProxy
        def self.handle?(store)
          defined?(::Redis::Store) && store.is_a?(::Redis::Store)
        end

        def initialize(store)
          super

          # with do |store|
            @get_method = ::Redis.instance_method(:get).bind(store)
            @set_method = ::Redis.instance_method(:set).bind(store)
            @setex_method = ::Redis.instance_method(:setex).bind(store)
          # end
        end

        def read(key)
          rescuing_with { @get_method.call(key) }
        end

        def write(key, value, options = {})
          if (expires_in = options[:expires_in])
            rescuing_with { @setex_method.call(key, expires_in, value) }
          else
            rescuing_with { @set_method.call(key, value) }
          end
        end
      end
    end
  end
end
