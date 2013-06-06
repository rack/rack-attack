module Rack
  module Attack
    class Cache

      attr_accessor :prefix

      def initialize
        self.store = ::Rails.cache if defined?(::Rails.cache)
        @prefix = 'rack::attack'
      end

      attr_reader :store
      def store=(store)
        # RedisStore#increment needs different behavior, so detect that
        # (method has an arity of 2; must call #expire separately
        if defined?(::ActiveSupport::Cache::RedisStore) && store.is_a?(::ActiveSupport::Cache::RedisStore)
          # ActiveSupport::Cache::RedisStore doesn't expose any way to set an expiry,
          # so use the raw Redis::Store instead
          @store = store.instance_variable_get(:@data)
        else
          @store = store
        end
      end

      def count(unprefixed_key, period)
        epoch_time = Time.now.to_i
        expires_in = period - (epoch_time % period)
        key = "#{prefix}:#{(epoch_time/period).to_i}:#{unprefixed_key}"
        do_count(key, expires_in)
      end

      def read(unprefixed_key)
        store.read("#{prefix}:#{unprefixed_key}")
      end
      
      def write(unprefixed_key, value, expires_in)
        store.write("#{prefix}:#{unprefixed_key}", value, :expires_in => expires_in)
      end

      private
      def do_count(key, expires_in)
        # Workaround Redis::Store's interface
        if defined?(::Redis::Store) && store.is_a?(::Redis::Store)
          result = store.incr(key)
          store.expire(key, expires_in)
        else
          result = store.increment(key, 1, :expires_in => expires_in)
        end
        # NB: Some stores return nil when incrementing uninitialized values
        if result.nil?
          store.write(key, 1, :expires_in => expires_in)
        end
        result || 1
      end

    end
  end
end
