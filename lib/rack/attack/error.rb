module Rack
  class Attack
    class HandlerError < StandardError
      ERROR_MESSAGE = 'You forgot to specify callback/block for rule `%s`'.freeze

      def initialize(scope)
        @scope = scope
        super(msg=format(ERROR_MESSAGE, scope))
      end
    end
  end
end
