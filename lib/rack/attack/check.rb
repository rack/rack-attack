module Rack
  class Attack
    class Check
      attr_reader :name, :block, :type
      def initialize(name, options = {}, block)
        @name, @block = name, block
        @type = options.fetch(:type, nil)
      end

      def [](req)
        block[req].tap {|match|
          if match
            req.env[Rack::Attack::MATCHED] = name
            req.env[Rack::Attack::MATCH_TYPE] = type
            Rack::Attack.instrument(req)
          end
        }
      end

    end
  end
end

