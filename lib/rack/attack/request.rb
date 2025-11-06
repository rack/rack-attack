# frozen_string_literal: true

# Rack::Attack::Request is the same as :ActionDispatch::Request in Rails apps,
# and ::Rack::Request in other apps by default.
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
    class Request < defined?(::ActionDispatch::Request) ? ::ActionDispatch::Request : ::Rack::Request
    end
  end
end
