require_relative 'check'
module Rack
  module Attack
    class Blacklist < Check
      def initialize(name, block)
        super
        @type = :blacklist
      end

    end
  end
end

