# frozen_string_literal: true

module Rack
  class Attack
    class Throttle
      MANDATORY_OPTIONS = [:limit, :period].freeze

      attr_reader :name, :limit, :period, :block, :type
      def initialize(name, options, &block)
        @name, @block = name, block
        MANDATORY_OPTIONS.each do |opt|
          raise ArgumentError, "Must pass #{opt.inspect} option" unless options[opt]
        end
        @limit  = options[:limit]
        @period = options[:period].respond_to?(:call) ? options[:period] : options[:period].to_i
        @type   = options.fetch(:type, :throttle)
      end

      def cache
        Rack::Attack.cache
      end

      def matched_by?(request)
        discriminator = block.call(request)
        return false unless discriminator

        current_period = period.respond_to?(:call) ? period.call(request) : period
        current_limit  = limit.respond_to?(:call) ? limit.call(request) : limit
        key            = "#{name}:#{discriminator}"
        count          = cache.count(key, current_period)
        epoch_time     = cache.last_epoch_time

        data = {
          count: count,
          period: current_period,
          limit: current_limit,
          epoch_time: epoch_time
        }

        (request.env['rack.attack.throttle_data'] ||= {})[name] = data

        (count > current_limit).tap do |throttled|
          if throttled
            request.env['rack.attack.matched']             = name
            request.env['rack.attack.match_discriminator'] = discriminator
            request.env['rack.attack.match_type']          = type
            request.env['rack.attack.match_data']          = data
            Rack::Attack.instrument(request)
          end
        end
      end
    end
  end
end
