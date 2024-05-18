# frozen_string_literal: true

module Rack
  class Attack
    class Postrequest < Check
      def initialize(name = nil, &block)
        super
        @type = :postrequest
      end

      def matched_by?(request, response)
        block.call(request, response).tap do |match|
          if match
            request.env["rack.attack.matched"] = name
            request.env["rack.attack.match_type"] = type
            Rack::Attack.instrument(request)
          end
        end
      end
    end
  end
end
