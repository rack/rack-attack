# frozen_string_literal: true

require_relative "../spec_helper"
require "timecop"

describe "allow2ban" do
  let(:notifications) { [] }

  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    Rack::Attack.blocklist("allow2ban pentesters") do |request|
      Rack::Attack::Allow2Ban.filter(request.ip, maxretry: 2, findtime: 30, bantime: 60) do
        request.path.include?("scarce-resource")
      end
    end
  end

  it "returns OK for many requests that doesn't match the filter" do
    get "/"
    assert_equal 200, last_response.status

    get "/"
    assert_equal 200, last_response.status
  end

  it "returns OK for first request that matches the filter" do
    get "/scarce-resource"
    assert_equal 200, last_response.status
  end

  it "forbids all access after reaching maxretry limit" do
    get "/scarce-resource"
    assert_equal 200, last_response.status

    get "/scarce-resource"
    assert_equal 200, last_response.status

    get "/scarce-resource"
    assert_equal 403, last_response.status

    get "/"
    assert_equal 403, last_response.status
  end

  it "restores access after bantime elapsed" do
    get "/scarce-resource"
    assert_equal 200, last_response.status

    get "/scarce-resource"
    assert_equal 200, last_response.status

    get "/"
    assert_equal 403, last_response.status

    Timecop.travel(60) do
      get "/"

      assert_equal 200, last_response.status
    end
  end

  it "does not forbid all access if maxrety condition is met but not within the findtime timespan" do
    get "/scarce-resource"
    assert_equal 200, last_response.status

    Timecop.travel(31) do
      get "/scarce-resource"
      assert_equal 200, last_response.status

      get "/"
      assert_equal 200, last_response.status
    end
  end

  it "notifies when the ban is applied, on the request that is still allowed through" do
    ActiveSupport::Notifications.subscribe("ban.rack_attack") do |_name, _start, _finish, _id, payload|
      notifications.push(payload)
    end

    get "/scarce-resource"

    assert_equal 200, last_response.status
    assert notifications.empty?, "should not notify before maxretry is reached"

    # Allow2Ban lets this request through, but the ban is written for the next
    # one -- this is the only point at which a ban can be observed.
    get "/scarce-resource"

    assert_equal 200, last_response.status
    assert_equal 1, notifications.size

    notification = notifications.pop
    assert_equal 'allow2ban', notification[:name]
    assert_equal '127.0.0.1', notification[:discriminator]
    assert_equal 2, notification[:count]
    assert_equal 2, notification[:maxretry]

    # Now banned: blocked, but the ban is not re-applied so nothing fires.
    get "/"

    assert_equal 403, last_response.status
    assert notifications.empty?
  end
end
