module Rack
  module Attack
    class Fail2Ban
      class << self
        def filter(discriminator, options)
          bantime   = options[:bantime]   or raise ArgumentError, "Must pass bantime option"
          findtime  = options[:findtime]  or raise ArgumentError, "Must pass findtime option"
          maxretry  = options[:maxretry]  or raise ArgumentError, "Must pass maxretry option"

          if banned?(discriminator)
            # Return true for blacklist
            true
          elsif yield
            fail!(discriminator, bantime, findtime, maxretry)
          end
        end

        private
        def fail!(discriminator, bantime, findtime, maxretry)
          count = cache.count("fail2ban:count:#{discriminator}", findtime)
          if count >= maxretry
            ban!(discriminator, bantime)
          end

          # Return true for blacklist
          true
        end

        def ban!(discriminator, bantime)
          cache.write("fail2ban:ban:#{discriminator}", 1, bantime)
        end

        def banned?(discriminator)
          cache.read("fail2ban:ban:#{discriminator}")
        end

        def cache
          Rack::Attack.cache
        end
      end
    end
  end
end
