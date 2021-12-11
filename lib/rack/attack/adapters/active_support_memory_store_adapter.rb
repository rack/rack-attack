# frozen_string_literal: true

require 'rack/attack/adapters/base'

module Rack
  class Attack
    module Adapters
      class ActiveSupportMemoryStoreAdapter < Base
        def read(key)
          backend.read(key)
        end

        def write(key, value, options)
          backend.write(key, value, options)
        end

        def increment(key, amount = 1, options = {})
          backend.synchronize do
            count = backend.read(key)
            expires_in = calculate_expiration_for(key, count, options[:expires_in])

            (count.to_i + amount).tap do |incremented|
              backend.write(key, incremented, expires_in: expires_in)
            end
          end
        end

        def delete(key)
          backend.delete(key)
        end

        def delete_matched(matcher)
          backend.delete_matched(matcher)
        end

        private

        def calculate_expiration_for(key, current_value, expires_in)
          epoch_time = Time.now.to_i

          if current_value
            previous_epoch_time, expires_in = expirations_cache[key]
            expires_in = expires_in - (epoch_time - previous_epoch_time)
          end

          expirations_cache[key] = [epoch_time, expires_in]
          expires_in
        end

        def expirations_cache
          @expirations_cache ||= {}
        end
      end
    end
  end
end
