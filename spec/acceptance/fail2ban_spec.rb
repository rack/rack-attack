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

  it "notifies once when the ban is applied, not on subsequent banned requests" do
    ActiveSupport::Notifications.subscribe("ban.rack_attack") do |_name, _start, _finish, _id, payload|
      notifications.push(payload)
    end

    get "/private-place"

    assert_equal 403, last_response.status
    assert notifications.empty?, "should not notify before maxretry is reached"

    # This request reaches maxretry and writes the ban.
    get "/private-place"

    assert_equal 403, last_response.status
    assert_equal 1, notifications.size

    notification = notifications.pop
    assert_equal 'fail2ban', notification[:name]
    assert_equal '127.0.0.1', notification[:discriminator]
    assert_equal 2, notification[:count]
    assert_equal 2, notification[:maxretry]
    assert_equal 30, notification[:findtime]
    assert_equal 60, notification[:bantime]

    # Already banned: blocked, but the ban is not re-applied so nothing fires.
    get "/"

    assert_equal 403, last_response.status
    assert notifications.empty?
  end

  it "omits the request from the ban payload when the filter is not given one" do
    ActiveSupport::Notifications.subscribe("ban.rack_attack") do |_name, _start, _finish, _id, payload|
      notifications.push(payload)
    end

    2.times { get "/private-place" }

    assert_equal 1, notifications.size
    assert_nil notifications.pop[:request]
  end

  it "includes the request in the ban payload when one is passed to the filter" do
    Rack::Attack.blocklist("fail2ban with request") do |request|
      Rack::Attack::Fail2Ban.filter("with-request:#{request.ip}",
                                    maxretry: 1, findtime: 30, bantime: 60, request: request) do
        request.path.include?("tarpit")
      end
    end

    ActiveSupport::Notifications.subscribe("ban.rack_attack") do |_name, _start, _finish, _id, payload|
      notifications.push(payload)
    end

    get "/tarpit"

    assert_equal 1, notifications.size
    assert_equal "/tarpit", notifications.pop[:request].path
  end
end
