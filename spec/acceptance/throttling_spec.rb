# frozen_string_literal: true

require_relative "../spec_helper"
require "timecop"

describe "#throttle" do
  let(:notifications) { [] }

  before do
    Rack::Attack.cache.store = SimpleMemoryStore.new
  end

  it "allows one request per minute by IP" do
    Rack::Attack.throttle("by ip", limit: 1, period: 60) do |request|
      request.ip
    end

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 200, last_response.status

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 429, last_response.status
    assert_nil last_response.headers["Retry-After"]
    assert_equal "Retry later\n", last_response.body

    get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert_equal 200, last_response.status

    Timecop.travel(60) do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 200, last_response.status
    end
  end

  it "returns correct Retry-After header if enabled" do
    Rack::Attack.throttled_response_retry_after_header = true

    Rack::Attack.throttle("by ip", limit: 1, period: 60) do |request|
      request.ip
    end

    Timecop.freeze(Time.at(0)) do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
      assert_equal 200, last_response.status
    end

    Timecop.freeze(Time.at(25)) do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
      assert_equal "35", last_response.headers["Retry-After"]
    end
  end

  it "supports limit to be dynamic" do
    # Could be used to have different rate limits for authorized
    # vs general requests
    limit_proc = lambda do |request|
      if request.env["X-APIKey"] == "private-secret"
        2
      else
        1
      end
    end

    Rack::Attack.throttle("by ip", limit: limit_proc, period: 60) do |request|
      request.ip
    end

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
    assert_equal 200, last_response.status

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
    assert_equal 429, last_response.status

    get "/", {}, "REMOTE_ADDR" => "5.6.7.8", "X-APIKey" => "private-secret"
    assert_equal 200, last_response.status

    get "/", {}, "REMOTE_ADDR" => "5.6.7.8", "X-APIKey" => "private-secret"
    assert_equal 200, last_response.status

    get "/", {}, "REMOTE_ADDR" => "5.6.7.8", "X-APIKey" => "private-secret"
    assert_equal 429, last_response.status
  end

  it "supports period to be dynamic" do
    # Could be used to have different rate limits for authorized
    # vs general requests
    period_proc = lambda do |request|
      if request.env["X-APIKey"] == "private-secret"
        10
      else
        30
      end
    end

    Rack::Attack.throttle("by ip", limit: 1, period: period_proc) do |request|
      request.ip
    end

    # Using Time#at to align to start/end of periods exactly
    # to achieve consistenty in different test runs

    Timecop.travel(Time.at(0)) do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
      assert_equal 200, last_response.status

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
      assert_equal 429, last_response.status
    end

    Timecop.travel(Time.at(10)) do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
      assert_equal 429, last_response.status
    end

    Timecop.travel(Time.at(30)) do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
      assert_equal 200, last_response.status
    end

    Timecop.travel(Time.at(0)) do
      get "/", {}, "REMOTE_ADDR" => "5.6.7.8", "X-APIKey" => "private-secret"
      assert_equal 200, last_response.status

      get "/", {}, "REMOTE_ADDR" => "5.6.7.8", "X-APIKey" => "private-secret"
      assert_equal 429, last_response.status
    end

    Timecop.travel(Time.at(10)) do
      get "/", {}, "REMOTE_ADDR" => "5.6.7.8", "X-APIKey" => "private-secret"
      assert_equal 200, last_response.status
    end
  end

  if defined?(::ActiveSupport::Notifications)
    it "notifies when the request is throttled" do
      Rack::Attack.throttle("by ip", limit: 1, period: 60) do |request|
        request.ip
      end

      ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
        notifications.push(payload)
      end

      get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

      assert_equal 200, last_response.status
      assert notifications.empty?

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 200, last_response.status
      assert notifications.empty?

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 429, last_response.status

      assert_equal 1, notifications.size
      notification = notifications.pop
      assert_equal "by ip", notification[:request].env["rack.attack.matched"]
      assert_equal :throttle, notification[:request].env["rack.attack.match_type"]
      assert_equal 60, notification[:request].env["rack.attack.match_data"][:period]
      assert_equal 1, notification[:request].env["rack.attack.match_data"][:limit]
      assert_equal 2, notification[:request].env["rack.attack.match_data"][:count]
      assert_equal "1.2.3.4", notification[:request].env["rack.attack.match_discriminator"]
    end
  end
end
