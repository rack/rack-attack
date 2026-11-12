# frozen_string_literal: true

module Rack
  class Attack
    class Fail2Ban
      class << self
        def filter(discriminator, options)
          bantime   = options[:bantime]   or raise ArgumentError, "Must pass bantime option"
          findtime  = options[:findtime]  or raise ArgumentError, "Must pass findtime option"
          maxretry  = options[:maxretry]  or raise ArgumentError, "Must pass maxretry option"

          if banned?(discriminator)
            # Return true for blocklist
            true
          elsif yield
            fail!(discriminator, bantime, findtime, maxretry)
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

        # Returns the number of seconds until the ban on discriminator expires,
        # rounded up to a whole second, or nil if discriminator is not banned.
        #
        # Also returns nil for bans created by versions of Rack::Attack that did not
        # store the ban expiration time, even though banned? is true for them.
        def retry_after(discriminator)
          banned_until = cache.read("#{key_prefix}:ban:#{discriminator}").to_f
          # Legacy bans store 1 instead of the expiration time
          return if banned_until <= 1

          [(banned_until - Time.now.to_f).ceil, 1].max
        end

        protected

        def key_prefix
          'fail2ban'
        end

        def fail!(discriminator, bantime, findtime, maxretry)
          count = cache.count("#{key_prefix}:count:#{discriminator}", findtime)
          if count >= maxretry
            ban!(discriminator, bantime)
          end

          true
        end

        private

        def ban!(discriminator, bantime)
          # Store the ban expiration time, since not every cache store can report the TTL of a key
          cache.write("#{key_prefix}:ban:#{discriminator}", Time.now.to_f + bantime.to_f, bantime)
        end

        def cache
          Rack::Attack.cache
        end
      end
    end
  end
end
