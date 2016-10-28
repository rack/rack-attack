module Rack
  class Attack
    class ThrottleWithLeakyBucket
      MANDATORY_OPTIONS = [:capacity, :leak]
      attr_reader :name, :capacity, :leak, :block, :type

      def initialize(name, options, block)
        @name, @block = name, block
        MANDATORY_OPTIONS.each do |opt|
          raise ArgumentError.new("Must pass #{opt.inspect} option") unless options[opt]
        end
        @capacity = options[:capacity]
        @leak     = options[:leak]
        @type     = options.fetch(:type, :throttle_with_leaky_bucket)
      end

      def cache
        Rack::Attack.cache
      end

      def [](req)
        discriminator = block[req]
        return false unless discriminator

        # Normalize blocks to values
        current_capacity = normalize_block(capacity, req)
        current_leak     = normalize_block(leak, req)

        # Read the bucket data and unserialize it. We only update the bucket data
        # if we've changed the value. We don't write to update the leaked amount
        # since that can be calculated and since the TTL will remove the item when
        # it has drained.
        key = "#{name}:#{discriminator}"
        bucket = LeakyBucket.unserialize(cache.read(key), current_capacity, current_leak)
        throttled = bucket.full?
        bucket.add(1) unless bucket.full?
        store_bucket(key, bucket) if bucket.updated?

        data = {
          :bucket => bucket,
          :leak => current_leak,
          :capacity => current_capacity
        }
        (req.env['rack.attack.throttle_with_leaky_bucket_data'] ||= {})[name] = data

        if throttled
          req.env['rack.attack.matched']             = name
          req.env['rack.attack.match_discriminator'] = discriminator
          req.env['rack.attack.match_type']          = type
          req.env['rack.attack.match_data']          = data
          Rack::Attack.instrument(req)
        end

        throttled
      end

      private

      def store_bucket(key, bucket)
        cache.write(key, bucket.serialize, bucket.seconds_until_drained.ceil)
      end

      def normalize_block(value_or_block, *args_for_block)
        value_or_block.respond_to?(:call) ? value_or_block.call(*args_for_block) : value_or_block
      end
    end
  end
end
