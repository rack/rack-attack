# frozen_string_literal: true

module Rack
  class Attack
    class Railtie < ::Rails::Railtie
      initializer "rack-attack.middleware" do |app|
        app.middleware.use(Rack::Attack)
      end
    end
  end
end
