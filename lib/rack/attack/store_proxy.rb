require 'delegate'

module Rack
  module Attack
    class StoreProxy
      def self.build(store)
        # RedisStore#increment needs different behavior, so detect that
        # (method has an arity of 2; must call #expire separately
        if defined?(::ActiveSupport::Cache::RedisStore) && store.is_a?(::ActiveSupport::Cache::RedisStore)
          # ActiveSupport::Cache::RedisStore doesn't expose any way to set an expiry,
          # so use the raw Redis::Store instead
          store = store.instance_variable_get(:@data)
        end

        if defined?(::Redis::Store) && store.is_a?(::Redis::Store)
          RedisStoreProxy.new(store)
        elsif defined?(::Dalli) && store.is_a?(::Dalli::Client)
          DalliProxy.new(store)
        else
          store
        end
      end

      class RedisStoreProxy < SimpleDelegator
        def initialize(store)
          super(store)
        end

        def read(key)
          self.get(key)
          rescue Redis::BaseError
            nil
        end

        def write(key, value, options={})
          if (expires_in = options[:expires_in])
            self.setex(key, expires_in, value)
          else
            self.set(key, value)
          end
          rescue Redis::BaseError
            nil
        end

        def increment(key, amount, options={})
          count = nil
          self.pipelined do
            count = self.incrby(key, amount)
            self.expire(key, options[:expires_in]) if options[:expires_in]
          end
          count.value if count
          rescue Redis::BaseError
            nil
        end

      end

      class DalliProxy < SimpleDelegator
        def initialize(client)
          super(client)
          stub_with_method_on_older_clients
        end

        def read(key)
          with do |client|
            client.get(key)
          end
        rescue Dalli::DalliError
        end

        def write(key, value, options={})
          with do |client|
            client.set(key, value, options.fetch(:expires_in, 0), raw: true)
          end
        rescue Dalli::DalliError
        end

        def increment(key, amount, options={})
          with do |client|
            client.incr(key, amount, options.fetch(:expires_in, 0), amount)
          end
        rescue Dalli::DalliError
        end

        private

        # So we support Dalli < 2.7.0
        def stub_with_method_on_older_clients
          unless __getobj__.respond_to?(:with)
            def __getobj__.with; yield self; end
          end
        end

      end
    end
  end
end
