module Rack
  module Attack
    class Track < Check
      def initialize(name, block)
        super
        @type = :track
      end
    end
  end
end
