module Rack
  class Attack
    class Track
      extend Forwardable

      attr_reader :checker

      def initialize(name, options = {}, block)
        options[:type] = :track

        if options[:limit] && options[:period]
          @checker = Throttle.new(name, options, block)
        else
          @checker = Check.new(name, options, block)
        end
      end

      def_delegator :@checker, :[], :[]
    end
  end
end
