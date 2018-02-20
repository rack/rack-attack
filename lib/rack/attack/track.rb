module Rack
  class Attack
    class Track
      extend Forwardable

      attr_reader :filter

      def initialize(name, options = {}, block)
        options[:type] = :track

        @filter = if options[:limit] && options[:period]
                    Throttle.new(name, options, block)
                  else
                    Check.new(name, options, block)
                  end
      end

      def_delegator :@filter, :[]
    end
  end
end
