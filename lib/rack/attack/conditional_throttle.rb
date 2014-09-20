module Rack
  class Attack
    class ConditionalThrottle < ::Rack::Attack::Throttle

      def increment_counter(discriminator)
        key = "#{name}:#{discriminator}"
        cache.count(key, period)
      end

      def get_count(discriminator)
        key = "#{name}:#{discriminator}"
        count = cache.get_count(key, period)
        count ? count.to_i : 0
      end
    end
  end
end
