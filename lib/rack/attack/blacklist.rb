module Rack
  class Attack
    class Blacklist < Check
      def initialize(name, block)
        super
        @type = :blacklist
      end

    end
  end
end

