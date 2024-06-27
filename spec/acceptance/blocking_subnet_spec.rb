# frozen_string_literal: true

require_relative "../spec_helper"

describe "Blocking an IP subnet" do
  let(:notifications) { [] }

  before do
    Rack::Attack.blocklist_ip("1.2.3.4/31")
  end

  it "forbids request if IP is inside the subnet" do
    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 403, last_response.status
  end

  it "forbids request for another IP in the subnet" do
    get "/", {}, "REMOTE_ADDR" => "1.2.3.5"

    assert_equal 403, last_response.status
  end

  it "succeeds if IP is outside the subnet" do
    get "/", {}, "REMOTE_ADDR" => "1.2.3.6"

    assert_equal 200, last_response.status
  end

  it "notifies when the request is blocked" do
    ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _id, payload|
      notifications.push(payload)
    end

    get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert notifications.empty?

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 1, notifications.size
    notification = notifications.pop
    assert_equal :blocklist, notification[:request].env["rack.attack.match_type"]
  end
end
