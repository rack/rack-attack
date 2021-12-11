# frozen_string_literal: true

require 'rack/attack/base_proxy'

module Rack
  class Attack
    module StoreProxy
      class ActiveSupportMemoryStoreProxy < BaseProxy
        def self.handle?(store)
          store.class.name == 'ActiveSupport::Cache::MemoryStore'
        end

        def increment(key, amount = 1, options = {})
          synchronize do
            count = read(key, options)
            expires_in = calculate_expiration_for(key, count, options[:expires_in])

            (count.to_i + amount).tap do |incremented|
              write(key, incremented, expires_in: expires_in)
            end
          end
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
