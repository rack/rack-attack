require_relative "../spec_helper"

describe "Customizing throttled response" do
  it "can be customized" do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    Rack::Attack.throttle("by ip", limit: 1, period: 60) do |request|
      request.ip
    end

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 200, last_response.status

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 429, last_response.status

    Rack::Attack.throttled_response = lambda do |env|
      [503, {}, ["Throttled"]]
    end

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 503, last_response.status
    assert_equal "Throttled", last_response.body
  end
end
