# Rack::Attack::Response extends from ::Rack::Response by default.
#
# The env hash is used by Rack::Attack to propagate information about the actions it performed
# during the request phase and, by extending the response class to store it, also
# during the response phase.
#
# This is a safe place to add custom helper methods to the response object
# through monkey patching:
#
#   class Rack::Attack::Response < ::Rack::Response
#     def ok_or_created?
#       ok? || created?
#     end
#   end
#
#   Rack::Attack.track_response("localhost") {|res| res.ok_or_created? }
#
module Rack
  class Attack
    class Response < ::Rack::Response
      attr_accessor :response, :env
      def initialize(response, env)
        super(response[2], response[0], response[1])
        @env = env
      end
    end
  end
end
