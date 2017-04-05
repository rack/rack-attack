module Rack
  class Attack
    class LeakyBucket
      attr_reader :value, :capacity, :leak, :last_updated_at

      def initialize(capacity, leak, last_updated_at, value = 0)
        raise ArgumentError, "wrong value for `leak`, must be larger than zero" unless leak > 0
        raise ArgumentError, "wrong value for `capacity`, must be larger than zero" unless capacity.to_i > 0

        @capacity = capacity.to_i
        @leak = leak.to_f
        @last_updated_at = (last_updated_at.to_f > 0 ? last_updated_at : Time.now).to_f
        @value = value.to_f > 0 ? value.to_f : 0
        @updated = false
      end

      def update_leak!
        @value = current_value
        @last_updated_at = Time.now.to_f
      end

      def current_value
        seconds_since_last_update = Time.now.to_f - @last_updated_at
        value = @value - (@leak * seconds_since_last_update)
        value > 0 ? value : 0
      end

      def seconds_until_drained
        current_value / @leak
      end

      def add(value_to_add)
        update_leak!
        @updated = true
        @value += value_to_add
      end

      def full?
        current_value + 1 > @capacity
      end

      def updated?
        @updated
      end

      def serialize
        "#{@value.to_f}|#{@last_updated_at.to_f}"
      end

      def self.unserialize(bucket_data, capacity, leak)
        value, last_updated_at = (bucket_data || "0|#{Time.now.to_f}").split("|", 2)
        new(capacity, leak, last_updated_at, value)
      end
    end
  end
end
