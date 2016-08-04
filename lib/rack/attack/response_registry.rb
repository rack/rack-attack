module Rack
  class Attack
    class ResponseRegistry
      def initialize(default:)
        @responses = {default: default}
      end

      def default=(res)
        @responses[:default] = res
      end

      def []=(name, res)
        @responses[name] = res
      end

      def [](name=nil)
        @responses[name] || @responses[:default]
      end
    end
  end
end
