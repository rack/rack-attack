# frozen_string_literal: true

require "rails"

module Rack
  class Attack
    class Railtie < ::Rails::Railtie
      # Initialize rack-attack own configuration object in application config
      config.rack_attack = ActiveSupport::OrderedOptions.new

      # Set Rack middleware position. By default it is unset.
      config.rack_attack.middleware_position = nil

      initializer "rack-attack.middleware" do |app|
        insert_middleware_at(app, app.config.rack_attack.middleware_position)
      end

      private

      def insert_middleware_at(app, position)
        if position.nil?
          app.middleware.use(Rack::Attack)
        elsif position.is_a?(Integer)
          app.middleware.insert_before(position, Rack::Attack)
        elsif position.is_a?(Hash)
          app.middleware.insert_before(position[:before], Rack::Attack) if position.key?(:before)
          app.middleware.insert_after(position[:after], Rack::Attack) if position.key?(:after)
        else
          raise <<~ERROR
            The middleware position you have set is invalid. Please be sure
            `config.rack_attack.middleware_position` is set up correctly.
          ERROR
        end
      end
    end
  end
end
