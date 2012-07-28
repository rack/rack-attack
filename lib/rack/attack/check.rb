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
            Rack::Attack.instrument(:type => type, :name => name, :request => req)
            req.env["rack.attack.#{type}"] = name
          end
        }
      end

    end
  end
end

