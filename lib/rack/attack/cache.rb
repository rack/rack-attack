module Rack
  module Attack
    class Cache

      attr_accessor :store
      def initialize
        @store = ::Rails.cache if defined?(::Rails.cache)
      end

      def count(key, expires_in)
        result = store.increment(1, :expires_in => expires_in)
        # NB: Some stores return nil when incrementing uninitialized values
        if result.nil?
          store.write(key, 1, :expires_in => expires_in)
        end
        result || 1
      end

    end
  end
end
