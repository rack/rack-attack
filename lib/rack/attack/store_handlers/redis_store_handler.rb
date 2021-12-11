# frozen_string_literal: true

module Rack
  class Attack
    module StoreHandlers
      module RedisStoreHandler
        extend StoreHandlers

        def self.handles?(store)
          defined?(::Redis::Store) && instance_of_or_pooled?(store, ::Redis::Store)
        end

        def self.adapter_class
          Adapters::RedisStoreAdapter
        end
      end
    end
  end
end
