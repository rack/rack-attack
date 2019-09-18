# frozen_string_literal: true

module Rack
  class Attack
    class Railtie < ::Rails::Railtie
      initializer 'rack.attack.middleware', after: :load_config_initializers, before: :build_middleware_stack do |app|
        middlewares = app.config.middleware

        operations =
          if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new("5")
            middlewares.send(:operations) + middlewares.send(:delete_operations)
          else
            middlewares.instance_variable_get(:@operations)
          end

        use_middleware = operations.none? do |operation|
          middleware = operation[1]
          middleware.include?(Rack::Attack)
        end

        middlewares.use(Rack::Attack) if use_middleware
      end
    end
  end
end
