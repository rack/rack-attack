# frozen_string_literal: true

require_relative "../spec_helper"

if defined?(Rails)
  describe "Middleware for Rails" do
    before do
      @app = Class.new(Rails::Application) do
        config.eager_load = false
        config.logger = Logger.new(nil) # avoid creating the log/ directory automatically
        config.cache_store = :null_store # avoid creating tmp/ directory for cache
      end
    end

    it "is placed at the end by default" do
      @app.initialize!

      assert @app.middleware.last == Rack::Attack
    end

    it "is placed at a specific index when the configured position is an integer" do
      old_config = @app.config.rack_attack.clone
      @app.config.rack_attack.middleware_position = 0

      @app.initialize!

      assert @app.middleware[0] == Rack::Attack

      @app.config.rack_attack = old_config
    end

    it "is placed before a specific middleware when configured with :before" do
      old_config = @app.config.rack_attack.clone
      @app.config.rack_attack.middleware_position = { before: Rack::Runtime }

      @app.initialize!

      middlewares = @app.middleware.middlewares
      assert middlewares.index(Rack::Attack) == middlewares.index(Rack::Runtime) - 1

      @app.config.rack_attack = old_config
    end

    it "is placed after a specific middleware when configured with :after" do
      old_config = @app.config.rack_attack.clone
      @app.config.rack_attack.middleware_position = { after: Rack::Runtime }

      @app.initialize!

      middlewares = @app.middleware.middlewares
      assert middlewares.index(Rack::Attack) == middlewares.index(Rack::Runtime) + 1

      @app.config.rack_attack = old_config
    end
  end
end
