module Rack
  module Attack
    class Check
      attr_reader :name, :block, :type
      def initialize(name, block)
        @name, @block = name, block
        @type = nil
      end

      def [](req)
        block[req].tap {|match|
          if match
            req.env["rack.attack.matched"] = {type => name}
            Rack::Attack.instrument(type, req)
          end
        }
      end

    end
  end
end

