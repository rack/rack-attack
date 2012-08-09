module Rack
  module Attack
    class Cache

      attr_accessor :store, :prefix
      def initialize
        @store = ::Rails.cache if defined?(::Rails.cache)
        @prefix = 'rack::attack'
      end

      def count(unprefixed_key, period)
        epoch_time = Time.now.to_i
        expires_in = period - (epoch_time % period)
        key = "#{prefix}:#{epoch_time/period}:#{unprefixed_key}"
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
