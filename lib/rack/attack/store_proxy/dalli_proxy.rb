# frozen_string_literal: true

require 'rack/attack/base_proxy'

module Rack
  class Attack
    module StoreProxy
      class DalliProxy < BaseProxy
        def self.handle?(store)
          return false unless defined?(::Dalli)

          # Consider extracting to a separate Connection Pool proxy to reduce
          # code here and handle clients other than Dalli.
          if defined?(::ConnectionPool) && store.is_a?(::ConnectionPool)
            store.with { |conn| conn.is_a?(::Dalli::Client) }
          else
            store.is_a?(::Dalli::Client)
          end
        end

        def read(key)
          rescuing_with do |client|
            client.get(key)
          end
        end

        def write(key, value, options = {})
          rescuing_with do |client|
            client.set(key, value, options.fetch(:expires_in, 0), raw: true)
          end
        end

        def increment(key, amount, options = {})
          rescuing_with do |client|
            client.incr(key, amount, options.fetch(:expires_in, 0), amount)
          end
        end

        def delete(key)
          rescuing_with do |client|
            client.delete(key)
          end
        end

        def flush_all
          rescuing_with do |client|
            client.flush_all
          end
        end

        private

        def rescuing_with
          with { |client| yield client }
        rescue Dalli::DalliError
          nil
        end
      end
    end
  end
end
