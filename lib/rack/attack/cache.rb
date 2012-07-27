module Rack
  module Attack
    class Cache

      attr_accessor :store, :prefix
      def initialize
        @store = ::Rails.cache if defined?(::Rails.cache)
        @prefix = 'rack::attack'
      end

      def count(unprefixed_key, expires_in)
        key = "#{prefix}:#{unprefixed_key}"
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
