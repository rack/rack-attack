# frozen_string_literal: true

module Rack
  class Attack
    class Fail2Ban
      class << self
        def filter(discriminator, options)
          bantime   = options[:bantime]   or raise ArgumentError, "Must pass bantime option"
          findtime  = options[:findtime]  or raise ArgumentError, "Must pass findtime option"
          maxretry  = options[:maxretry]  or raise ArgumentError, "Must pass maxretry option"
          request = options[:request]

          if banned?(discriminator)
            # Return true for blocklist
            true
          elsif yield
            fail!(discriminator, bantime, findtime, maxretry, request)
          end
        end

        def reset(discriminator, options)
          findtime = options[:findtime] or raise ArgumentError, "Must pass findtime option"
          cache.reset_count("#{key_prefix}:count:#{discriminator}", findtime)
          # Clear ban flag just in case it's there
          cache.delete("#{key_prefix}:ban:#{discriminator}")
        end

        def banned?(discriminator)
          cache.read("#{key_prefix}:ban:#{discriminator}") ? true : false
        end

        protected

        def key_prefix
          'fail2ban'
        end

        def fail!(discriminator, bantime, findtime, maxretry, request)
          count = cache.count("#{key_prefix}:count:#{discriminator}", findtime)
          if count >= maxretry
            ban!(discriminator, bantime)

            if request # must be passed in just for instrumentation
              annotate_request_with_matched_data(
                request,
                name: key_prefix,
                discriminator: discriminator,
                count: count,
                maxretry: maxretry,
                findtime: findtime,
                bantime: bantime
              )
              Rack::Attack.instrument(request)
            end
          end

          true
        end

        private

        def ban!(discriminator, bantime)
          cache.write("#{key_prefix}:ban:#{discriminator}", 1, bantime)
        end

        def cache
          Rack::Attack.cache
        end

        def annotate_request_with_matched_data(request, data)
          request.env['rack.attack.matched']             = data[:name]
          request.env['rack.attack.match_discriminator'] = data[:discriminator]
          request.env['rack.attack.match_type']          = :ban
          request.env['rack.attack.match_data']          = data
        end
      end
    end
  end
end
