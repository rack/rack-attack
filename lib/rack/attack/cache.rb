module Rack
  class Attack
    class Cache

      attr_accessor :prefix

      def initialize
        self.store = ::Rails.cache if defined?(::Rails.cache)
        @prefix = 'rack::attack'
      end

      attr_reader :store
      def store=(store)
        @store = StoreProxy.build(store)
      end

      def count(unprefixed_key, period)
        epoch_time = Time.now.to_i
        # Add 1 to expires_in to avoid timing error: http://git.io/i1PHXA
        expires_in = period - (epoch_time % period) + 1
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
        result = store.increment(key, 1, :expires_in => expires_in)

        # NB: Some stores return nil when incrementing uninitialized values
        if result.nil?
          store.write(key, 1, :expires_in => expires_in)
        end
        result || 1
      end

    end
  end
end
