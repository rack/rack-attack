# frozen_string_literal: true

require_relative "../spec_helper"

describe "Safelisting an IP subnet" do
  let(:notifications) { [] }

  before do
    Rack::Attack.blocklist("admin") do |request|
      request.path == "/admin"
    end

    Rack::Attack.safelist_ip("5.6.0.0/16")
  end

  it "forbids request if blocklist condition is true and safelist is false" do
    get "/admin", {}, "REMOTE_ADDR" => "5.7.0.0"

    assert_equal 403, last_response.status
  end

  it "succeeds if blocklist condition is false and safelist is false" do
    get "/", {}, "REMOTE_ADDR" => "5.7.0.0"

    assert_equal 200, last_response.status
  end

  it "succeeds request if blocklist condition is false and safelist is true" do
    get "/", {}, "REMOTE_ADDR" => "5.6.0.0"

    assert_equal 200, last_response.status
  end

  it "succeeds request if both blocklist and safelist conditions are true" do
    get "/admin", {}, "REMOTE_ADDR" => "5.6.255.255"

    assert_equal 200, last_response.status
  end

  it "notifies when the request is safe" do
    ActiveSupport::Notifications.subscribe("safelist.rack_attack") do |_name, _start, _finish, _id, payload|
      notifications.push(payload)
    end

    get "/admin", {}, "REMOTE_ADDR" => "5.6.0.0"

    assert_equal 200, last_response.status
    assert_equal 1, notifications.size
    notification = notifications.pop
    assert_equal :safelist, notification[:request].env["rack.attack.match_type"]
  end
end
