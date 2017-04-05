require 'delegate'

module Rack
  class Attack
    module StoreProxy
      class RedisStoreProxy < SimpleDelegator
        def self.handle?(store)
          return false unless defined?(::Redis::Store)

          # Consider extracting to a separate Connection Pool proxy to reduce
          # code here and handle clients other than Redis::Store.
          if defined?(::ConnectionPool) && store.is_a?(::ConnectionPool)
            store.with { |conn| conn.is_a?(::Redis::Store) }
          else
            store.is_a?(::Redis::Store)
          end
        end

        def initialize(store)
          super(store)
          stub_with_if_missing
        end

        def read(key)
          with do |client|
            client.get(key, raw: true)
          end
        rescue Redis::BaseError
        end

        def write(key, value, options={})
          with do |client|
            if (expires_in = options[:expires_in])
              client.setex(key, expires_in, value, raw: true)
            else
              client.set(key, value, raw: true)
            end
          end
        rescue Redis::BaseError
        end

        def increment(key, amount, options={})
          count = nil
          with do |client|
            client.pipelined do
              count = client.incrby(key, amount)
              client.expire(key, options[:expires_in]) if options[:expires_in]
            end
          end
          count.value if count
        rescue Redis::BaseError
        end

        def delete(key, options={})
          with do |client|
            client.del(key)
          end
        rescue Redis::BaseError
        end

        private

        def stub_with_if_missing
          unless __getobj__.respond_to?(:with)
            class << self
              def with; yield __getobj__; end
            end
          end
        end
      end
    end
  end
end
