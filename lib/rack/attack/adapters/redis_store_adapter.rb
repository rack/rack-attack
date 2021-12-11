# frozen_string_literal: true

require 'rack/attack/adapters/redis_adapter'

module Rack
  class Attack
    module Adapters
      class RedisStoreAdapter < RedisAdapter
        def read(key)
          with { |rs| rs.get(key, raw: true) }
        end

        def write(key, value, options = {})
          with do |rs|
            if (expires_in = options[:expires_in])
              rs.setex(key, expires_in, value, raw: true)
            else
              rs.set(key, value, raw: true)
            end
          end
        end
      end
    end
  end
end
