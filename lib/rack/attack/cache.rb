# frozen_string_literal: true

module Rack
  class Attack
    class Cache
      attr_accessor :prefix
      attr_reader :last_epoch_time
      attr_reader :last_retry_after_time

      def initialize
        self.store = ::Rails.cache if defined?(::Rails.cache)
        @prefix = 'rack::attack'
      end

      attr_reader :store

      def store=(store)
        @store =
          if (proxy = BaseProxy.lookup(store))
            proxy.new(store)
          else
            store
          end
      end

      def count(unprefixed_key, period, use_offset = false)
        key, expires_in = key_and_expiry(unprefixed_key, period, use_offset)
        do_count(key, expires_in)
      end

      def read(unprefixed_key)
        enforce_store_presence!
        enforce_store_method_presence!(:read)

        store.read("#{prefix}:#{unprefixed_key}")
      end

      def write(unprefixed_key, value, expires_in)
        store.write("#{prefix}:#{unprefixed_key}", value, expires_in: expires_in)
      end

      def reset_count(unprefixed_key, period)
        key, _ = key_and_expiry(unprefixed_key, period)
        store.delete(key)
      end

      def delete(unprefixed_key)
        store.delete("#{prefix}:#{unprefixed_key}")
      end

      def reset!
        if store.respond_to?(:delete_matched)
          store.delete_matched("#{prefix}*")
        else
          raise(
            Rack::Attack::IncompatibleStoreError,
            "Configured store #{store.class.name} doesn't respond to #delete_matched method"
          )
        end
      end

      private

      def key_and_expiry(unprefixed_key, period, use_offset = false)
        @last_epoch_time = Time.now.to_i
        offset = offset_for(unprefixed_key, period, use_offset)
        period_number, time_into_period = period_number_and_time_into(period, offset)
        period_remainder = period - time_into_period
        @last_retry_after_time = @last_epoch_time + period_remainder
        # Add 1 to expires_in to avoid timing error: https://git.io/i1PHXA
        expires_in = period_remainder + 1
        ["#{prefix}:#{period_number}:#{unprefixed_key}", expires_in]
      end

      def offset_for(unprefixed_key, period, use_offset)
        0
      end

      def period_number_and_time_into(period, offset)
        [((@last_epoch_time + offset) / period).to_i, (@last_epoch_time + offset) % period]
      end

      def do_count(key, expires_in)
        enforce_store_presence!
        enforce_store_method_presence!(:increment)

        result = store.increment(key, 1, expires_in: expires_in)

        # NB: Some stores return nil when incrementing uninitialized values
        if result.nil?
          enforce_store_method_presence!(:write)

          store.write(key, 1, expires_in: expires_in)
        end
        result || 1
      end

      def enforce_store_presence!
        if store.nil?
          raise Rack::Attack::MissingStoreError
        end
      end

      def enforce_store_method_presence!(method_name)
        if !store.respond_to?(method_name)
          raise(
            Rack::Attack::MisconfiguredStoreError,
            "Configured store #{store.class.name} doesn't respond to ##{method_name} method"
          )
        end
      end
    end
  end
end
