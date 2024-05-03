# frozen_string_literal: true

require_relative "../spec_helper"
require "timecop"

describe "fail2ban" do
  let(:notifications) { [] }

  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    Rack::Attack.blocklist("fail2ban pentesters") do |request|
      Rack::Attack::Fail2Ban.filter(request.ip, maxretry: 2, findtime: 30, bantime: 60) do
        request.path.include?("private-place")
      end
    end
  end

  it "returns OK for many requests to non filtered path" do
    get "/"
    assert_equal 200, last_response.status

    get "/"
    assert_equal 200, last_response.status
  end

  it "forbids access to private path" do
    get "/private-place"
    assert_equal 403, last_response.status
  end

  it "returns OK for non filtered path if yet not reached maxretry limit" do
    get "/private-place"
    assert_equal 403, last_response.status

    get "/"
    assert_equal 200, last_response.status
  end

  it "forbids all access after reaching maxretry limit" do
    get "/private-place"
    assert_equal 403, last_response.status

    get "/private-place"
    assert_equal 403, last_response.status

    get "/"
    assert_equal 403, last_response.status
  end

  it "restores access after bantime elapsed" do
    get "/private-place"
    assert_equal 403, last_response.status

    get "/private-place"
    assert_equal 403, last_response.status

    get "/"
    assert_equal 403, last_response.status

    Timecop.travel(60) do
      get "/"

      assert_equal 200, last_response.status
    end
  end

  it "does not forbid all access if maxrety condition is met but not within the findtime timespan" do
    get "/private-place"
    assert_equal 403, last_response.status

    Timecop.travel(31) do
      get "/private-place"
      assert_equal 403, last_response.status

      get "/"
      assert_equal 200, last_response.status
    end
  end

  it "notifies when the request is blocked" do
    ActiveSupport::Notifications.subscribe("rack.attack") do |_name, _start, _finish, _id, payload|
      notifications.push(payload)
    end

    get "/"

    assert_equal 200, last_response.status
    assert notifications.empty?

    get "/private-place"

    assert_equal 403, last_response.status
    assert_equal 1, notifications.size
    notification = notifications.pop
    assert_equal 'fail2ban pentesters', notification[:request].env["rack.attack.matched"]
    assert_equal :blocklist, notification[:request].env["rack.attack.match_type"]

    get "/"

    assert_equal 200, last_response.status
    assert notifications.empty?

    get "/private-place"

    assert_equal 403, last_response.status
    assert_equal 1, notifications.size
    notification = notifications.pop
    assert_equal 'fail2ban pentesters', notification[:request].env["rack.attack.matched"]
    assert_equal :blocklist, notification[:request].env["rack.attack.match_type"]

    get "/"

    assert_equal 403, last_response.status
    assert_equal 1, notifications.size
    notification = notifications.pop
    assert_equal 'fail2ban pentesters', notification[:request].env["rack.attack.matched"]
    assert_equal :blocklist, notification[:request].env["rack.attack.match_type"]
  end
end
