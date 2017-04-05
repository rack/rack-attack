require 'ipaddr'

# Rack::Attack::Request is the same as ::Rack::Request by default.
#
# This is a safe place to add custom helper methods to the request object
# through monkey patching:
#
#   class Rack::Attack::Request < ::Rack::Request
#     def localhost?
#       ip == "127.0.0.1"
#     end
#   end
#
#   Rack::Attack.safelist("localhost") {|req| req.localhost? }
#
module Rack
  class Attack
    class Request < ::Rack::Request
      # A memoized instance of an IPAddr, derived from the "ip" value.
      def ip_addr
        @ip_addr ||= IPAddr.new(ip)
      end
    end
  end
end
