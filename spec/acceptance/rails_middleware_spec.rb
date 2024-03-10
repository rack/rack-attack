# frozen_string_literal: true

require_relative "../spec_helper"

if defined?(Rails::Application)
  describe "Middleware for Rails" do
    before do
      @app = Class.new(Rails::Application) do
        config.eager_load = false
        config.logger = Logger.new(nil) # avoid creating the log/ directory automatically
        config.cache_store = :null_store # avoid creating tmp/ directory for cache
      end
    end

    it "is used by default" do
      @app.initialize!
      assert @app.middleware.include?(Rack::Attack)
    end

    it "can be configured via a block" do
      @app.middleware.delete(Rack::Attack)
      @app.middleware.use(Rack::Attack) do
        blocklist_ip("1.2.3.4")
      end
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
      assert_equal 403, last_response.status

      get "/", {}, "REMOTE_ADDR" => "4.3.2.1"
      assert_equal 200, last_response.status
    end
  end
end
