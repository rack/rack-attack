# frozen_string_literal: true

require_relative "../spec_helper"

if defined?(::ActiveSupport::Notifications)
  describe "#blocklist" do
    let(:notifications) { [] }

    before do
      Rack::Attack.blocklist do |request|
        request.ip == "1.2.3.4"
      end
    end

    it "forbids request if blocklist condition is true" do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 403, last_response.status
    end

    it "succeeds if blocklist condition is false" do
      get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

      assert_equal 200, last_response.status
    end

    it "notifies when the request is blocked" do
      ActiveSupport::Notifications.subscribe("rack.attack") do |_name, _start, _finish, _id, payload|
        notifications.push(payload)
      end

      get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

      assert notifications.empty?

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 1, notifications.size
      notification = notifications.pop
      assert_nil notification[:request].env["rack.attack.matched"]
      assert_equal :blocklist, notification[:request].env["rack.attack.match_type"]
    end
  end

  describe "#blocklist with name" do
    let(:notifications) { [] }

    before do
      Rack::Attack.blocklist("block 1.2.3.4") do |request|
        request.ip == "1.2.3.4"
      end
    end

    it "forbids request if blocklist condition is true" do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 403, last_response.status
    end

    it "succeeds if blocklist condition is false" do
      get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

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
      assert_equal "block 1.2.3.4", notification[:request].env["rack.attack.matched"]
      assert_equal :blocklist, notification[:request].env["rack.attack.match_type"]
    end
  end
end
