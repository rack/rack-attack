# frozen_string_literal: true

require_relative "../spec_helper"

describe "Safelist an IP" do
  before do
    Rack::Attack.blocklist("admin") do |request|
      request.path == "/admin"
    end

    Rack::Attack.safelist_ip("5.6.7.8")
  end

  it "forbids request if blocklist condition is true and safelist is false" do
    get "/admin", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 403, last_response.status
  end

  it "forbids request if blocklist condition is true and safelist is false (missing IP)" do
    get "/admin", {}, "REMOTE_ADDR" => ""

    assert_equal 403, last_response.status
  end

  it "succeeds if blocklist condition is false and safelist is false" do
    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 200, last_response.status
  end

  it "succeeds request if blocklist condition is false and safelist is true" do
    get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert_equal 200, last_response.status
  end

  it "succeeds request if both blocklist and safelist conditions are true" do
    get "/admin", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert_equal 200, last_response.status
  end

  it "notifies when the request is safe" do
    notification_type = nil

    ActiveSupport::Notifications.subscribe("safelist.rack_attack") do |_name, _start, _finish, _id, payload|
      notification_type = payload[:request].env["rack.attack.match_type"]
    end

    get "/admin", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert_equal 200, last_response.status
    assert_equal :safelist, notification_type
  end
end
