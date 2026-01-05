# frozen_string_literal: true

require_relative "../spec_helper"

if defined?(::ActiveSupport::Notifications)
  describe "Blocking an IP" do
    let(:notifications) { [] }

    before do
      Rack::Attack.blocklist_ip("1.2.3.4")
    end

    it "forbids request if IP matches" do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 403, last_response.status
    end

    it "succeeds if IP doesn't match" do
      get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

      assert_equal 200, last_response.status
    end

    it "succeeds if IP is missing" do
      get "/", {}, "REMOTE_ADDR" => ""

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
end
