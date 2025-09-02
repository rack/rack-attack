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

        def initialize(client, **options)
          super(client, **options)
          stub_with_if_missing
        end

        def read(key)
          handle_store_error do
            with do |client|
              client.get(key)
            end
          end
        end

        def write(key, value, options = {})
          handle_store_error do
            with do |client|
              client.set(key, value, options.fetch(:expires_in, 0), raw: true)
            end
          end
        end

        def increment(key, amount, options = {})
          handle_store_error do
            with do |client|
              client.incr(key, amount, options.fetch(:expires_in, 0), amount)
            end
          end
        end

        def delete(key)
          handle_store_error do
            with do |client|
              client.delete(key)
            end
          end
        end

        private

        def stub_with_if_missing
          unless __getobj__.respond_to?(:with)
            class << self
              def with
                yield __getobj__
              end
            end
          end
        end

        def should_bypass_error?(error)
          # Dalli-specific default behavior: bypass Dalli errors
          return true if defined?(::Dalli::DalliError) && error.is_a?(Dalli::DalliError)
          super
        end
      end
    end
  end
end
