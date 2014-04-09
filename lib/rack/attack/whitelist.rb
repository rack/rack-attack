module Rack
  class Attack
    class Whitelist < Check
      def initialize(name, block)
        super
        @type = :whitelist
      end

    end
  end
end
