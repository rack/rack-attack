module Rack
  module Attack
    class Throttle
      MANDATORY_OPTIONS = [:limit, :period]
      attr_reader :name, :limit, :period, :block, :proceed_on_error
      def initialize(name, options, block)
        @name, @block = name, block
        MANDATORY_OPTIONS.each do |opt|
          raise ArgumentError.new("Must pass #{opt.inspect} option") unless options[opt]
        end
        @limit  = options[:limit]
        @period = options[:period].to_i
        @proceed_on_error = options[:proceed_on_error]
      end

      def cache
        Rack::Attack.cache
      end

      def [](req)
        discriminator = block[req]
        return false unless discriminator

        key = "#{name}:#{discriminator}"
        count = nil
        if @proceed_on_error
          begin
            count = cache.count(key, period)
          rescue => e
            populate_env(req, name)
            req.env['rack.attack.exception'] = e.message
            Rack::Attack.instrument(req)
            return
          end
        else
          count = cache.count(key, period)
        end

        current_limit = limit.respond_to?(:call) ? limit.call(req) : limit
        data = {
          :count => count,
          :period => period,
          :limit => current_limit
        }
        (req.env['rack.attack.throttle_data'] ||= {})[name] = data

        (count > current_limit).tap do |throttled|
          if throttled
            populate_env(req, name, data)
            Rack::Attack.instrument(req)
          end
        end
      end
      def populate_env(request, name, data = nil)
        request.env['rack.attack.matched']    = name
        request.env['rack.attack.match_type'] = :throttle
        request.env['rack.attack.match_data'] = data if !data.nil?
      end
    end
  end
end
