module Rack
  class Attack
    class Meter
      MANDATORY_OPTIONS = [:limit, :period]

      attr_reader :name, :limit, :period, :block, :type

      def initialize(name, options, block)
        @name, @block = name, block

        MANDATORY_OPTIONS.each do |opt|
          raise ArgumentError.new("Must pass #{opt.inspect} option") unless options[opt]
        end

        @limit  = options[:limit]
        @period = options[:period].to_i
        @type   = :meter
      end

      def cache
        Rack::Attack.cache
      end

      def [](req)
        discriminator = block[req]
        return false unless discriminator

        key           = "#{name}:#{discriminator}"
        count         = cache.count(key, period)
        current_limit = limit.respond_to?(:call) ? limit.call(req) : limit
        data          = {
          :count  => count,
          :period => period,
          :limit  => current_limit
        }

        (req.env["rack.attack.#{type.to_s}_data"] ||= {})[name] = data

        (count > current_limit).tap do |limited|
          if limited
            req.env['rack.attack.matched']             = name
            req.env['rack.attack.match_discriminator'] = discriminator
            req.env['rack.attack.match_type']          = type
            req.env['rack.attack.match_data']          = data
            Rack::Attack.instrument(req)
          end
        end
      end
    end
  end
end
