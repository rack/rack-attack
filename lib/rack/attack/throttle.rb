module Rack
  class Attack
    class Throttle < Meter
      def initialize(name, options, block)
        super
        @type = :throttle
      end
    end
  end
end
