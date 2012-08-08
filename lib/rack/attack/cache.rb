module Rack
  module Attack
    class Cache

      attr_accessor :store, :prefix
      def initialize
        @store = ::Rails.cache if defined?(::Rails.cache)
        @prefix = 'rack::attack'
      end

      def count(unprefixed_key, period)
        key = "#{prefix}:#{Time.now.to_i/period}:#{unprefixed_key}"
        result = store.increment(key, 1)
        # NB: Some stores return nil when incrementing uninitialized values
        if result.nil?
          store.write(key, 1)
        end
        result || 1
      end

    end
  end
end
