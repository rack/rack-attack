# frozen_string_literal: true

require_relative "../spec_helper"

describe "Middleware" do
  it "is used in Rails by default" do
    skip unless defined?(Rails)

    app = Class.new(Rails::Application) do
      config.eager_load = false
      config.logger = Logger.new(nil) # avoid creating the log/ directory automatically
      config.cache_store = :null_store # avoid creating tmp/ directory for cache
    end

    app.initialize!
    assert app.middleware.include?(Rack::Attack)
  end

  def app
    Rack::Builder.new do
      use Rack::Attack do
        blocklist_ip("1.2.3.4")
      end

      run lambda { |_env| [200, {}, ['Hello World']] }
    end.to_app
  end

  it "can be configured via a block" do
    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
    assert_equal 403, last_response.status

    get "/", {}, "REMOTE_ADDR" => "4.3.2.1"
    assert_equal 200, last_response.status
  end
end
