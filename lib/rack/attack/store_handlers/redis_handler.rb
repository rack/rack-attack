# frozen_string_literal: true

module Rack
  class Attack
    module StoreHandlers
      module RedisHandler
        extend StoreHandlers

        def self.handles?(store)
          defined?(::Redis) && (instance_of_or_pooled?(store, ::Redis) || redis_distributed?(store))
        end

        def self.redis_distributed?(store)
          defined?(::Redis::Distributed) && store.instance_of?(::Redis::Distributed)
        end

        def self.adapter_class
          Adapters::RedisAdapter
        end
      end
    end
  end
end
