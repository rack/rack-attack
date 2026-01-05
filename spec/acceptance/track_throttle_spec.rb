# frozen_string_literal: true

require_relative "../spec_helper"
require "timecop"

if defined?(::ActiveSupport::Cache::MemoryStore)
  describe "#track with throttle-ish options" do
    let(:notifications) { [] }

    it "notifies when throttle goes over the limit without actually throttling requests" do
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

      Rack::Attack.track("by ip", limit: 1, period: 60) do |request|
        request.ip
      end

      ActiveSupport::Notifications.subscribe("track.rack_attack") do |_name, _start, _finish, _id, payload|
        notifications.push(payload)
      end

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert notifications.empty?

      assert_equal 200, last_response.status

      get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

      assert notifications.empty?

      assert_equal 200, last_response.status

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 1, notifications.size
      notification = notifications.pop
      assert_equal "by ip", notification[:request].env["rack.attack.matched"]
      assert_equal :track, notification[:request].env["rack.attack.match_type"]

      assert_equal 200, last_response.status

      Timecop.travel(60) do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert notifications.empty?

        assert_equal 200, last_response.status
      end
    end
  end
end
