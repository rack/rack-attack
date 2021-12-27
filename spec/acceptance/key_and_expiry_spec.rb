# frozen_string_literal: true

require_relative "../spec_helper"
require "timecop"

describe "Behavior of key_and_expiry" do
  it "forms keys and expirations without offset as expected" do
    unprefixed_key = "abc789"
    period = 1000
    time = Time.at(1_000_000_000)

    Timecop.freeze(time) do
      key, expiry = Rack::Attack.cache.send(:key_and_expiry, unprefixed_key, period, false)
      assert_equal "rack::attack:1000000:abc789", key
      assert_equal 1001, expiry
    end
  end

  it "forms keys and expirations with offset as expected" do
    unprefixed_key = "abc789"
    period = 1000
    time = Time.at(1_000_000_000)

    Timecop.freeze(time) do
      Rack::Attack.cache.stub :offset_for, 0 do
        key, expiry = Rack::Attack.cache.send(:key_and_expiry, unprefixed_key, period, true)
        assert_equal "rack::attack:1000000:abc789", key
        assert_equal 1001, expiry
      end

      Rack::Attack.cache.stub :offset_for, 123 do
        key, expiry = Rack::Attack.cache.send(:key_and_expiry, unprefixed_key, period, true)
        assert_equal "rack::attack:1000000:abc789", key
        assert_equal 1001 - 123, expiry
      end

      Digest::MD5.stub :hexdigest, "123" do
        key, expiry = Rack::Attack.cache.send(:key_and_expiry, unprefixed_key, period, true)
        assert_equal "rack::attack:1000000:abc789", key
        assert_equal 1001 - "123".hex, expiry
      end
    end
  end

  it "expires correctly when period is 1 second" do
    Timecop.freeze do
      current_epoch = Time.now.to_i
      key, expiry = Rack::Attack.cache.send(:key_and_expiry, "abc789", 1)
      assert_equal "rack::attack:#{current_epoch}:abc789", key
      assert_equal 2, expiry
    end
  end
end
