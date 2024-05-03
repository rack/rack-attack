# frozen_string_literal: true

require_relative "../spec_helper"

describe "#track" do
  let(:notifications) { [] }

  it "notifies when track block returns true" do
    Rack::Attack.track("ip 1.2.3.4") do |request|
      request.ip == "1.2.3.4"
    end

    ActiveSupport::Notifications.subscribe("track.rack_attack") do |_name, _start, _finish, _id, payload|
      notifications.push(payload)
    end

    get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert notifications.empty?

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 1, notifications.size
    notification = notifications.pop
    assert_equal "ip 1.2.3.4", notification[:request].env["rack.attack.matched"]
    assert_equal :track, notification[:request].env["rack.attack.match_type"]
  end
end
