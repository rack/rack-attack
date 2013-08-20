module Rack
  module Attack
    class Throttle
      MANDATORY_OPTIONS = [:limit, :period]
      attr_reader :name, :limit, :period, :block
      def initialize(name, options, block)
        @name, @block = name, block
        MANDATORY_OPTIONS.each do |opt|
          raise ArgumentError.new("Must pass #{opt.inspect} option") unless options[opt]
        end
        @limit  = options[:limit]
        @period = options[:period].to_i
      end

      def cache
        Rack::Attack.cache
      end

      def [](req)
        discriminator = block[req]
        return false unless discriminator

        key = "#{name}:#{discriminator}"
        count = cache.count(key, period)
        current_limit = limit.respond_to?(:call) ? limit.call(req) : limit
        data = {
          :count => count,
          :period => period,
          :limit => current_limit
        }
        (req.env['rack.attack.throttle_data'] ||= {})[name] = data

        (count > current_limit).tap do |throttled|
          if throttled
            req.env['rack.attack.matched']    = name
            req.env['rack.attack.match_type'] = :throttle
            req.env['rack.attack.match_data'] = data
            Rack::Attack.instrument(req)
          end
        end
      end
    end
  end
end
