require_relative "../spec_helper"
require "timecop"

describe "#throttle" do
  it "allows one request per minute by IP" do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    Rack::Attack.throttle("by ip", limit: 1, period: 60) do |request|
      request.ip
    end

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 200, last_response.status

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 429, last_response.status

    get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert_equal 200, last_response.status

    Timecop.travel(60) do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 200, last_response.status
    end
  end
end
