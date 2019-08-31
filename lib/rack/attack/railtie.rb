# frozen_string_literal: true

module Rack
  class Attack
    class Railtie < Rails::Railtie
      config.after_initialize do |app|
        include_middleware = app.middleware.none? { |m| m == Rack::Attack }
        app.middleware.use(Rack::Attack) if include_middleware
      end
    end
  end
end
