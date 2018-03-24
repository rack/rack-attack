module Rack
  class Attack
    class Check
      attr_reader :name, :block, :type

      def initialize(name, options = {}, block)
        @name = name
        @block = block
        @type = options.fetch(:type, nil)
      end

      def [](req)
        block[req].tap do |match|
          if match
            req.env["rack.attack.matched"] = name
            req.env["rack.attack.match_type"] = type
            Rack::Attack.instrument(req)
          end
        end
      end
    end
  end
end
