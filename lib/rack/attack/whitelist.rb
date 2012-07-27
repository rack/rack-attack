module Rack
  module Attack
    class Whitelist
      attr_reader :name, :block
      def initialize(name, &block)
        @name, @block = name, block
      end

      def [](req)
      end

    end
  end
end
